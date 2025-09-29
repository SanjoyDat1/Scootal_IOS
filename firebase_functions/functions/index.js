const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(functions.config().stripe.secret_key);

admin.initializeApp();

/**
 * Creates a Stripe Connected Account for scooter owners
 * This allows them to receive payments when their scooters are rented
 */
exports.createConnectedAccount = functions.https.onCall(async (data, context) => {
  const {email, ownerId} = data;

  try {
    // Check if account already exists
    const providerDoc = await admin.firestore()
        .collection("providers")
        .doc(ownerId)
        .get();

    let accountId;

    if (providerDoc.exists && providerDoc.data().stripeAccountId) {
      accountId = providerDoc.data().stripeAccountId;
      console.log(`Using existing account: ${accountId}`);
    } else {
      // Create a new Connected Account
      const account = await stripe.accounts.create({
        type: "express",
        email: email,
        capabilities: {
          card_payments: {requested: true},
          transfers: {requested: true},
        },
      });

      accountId = account.id;

      // Save to Firestore
      await admin.firestore().collection("providers").doc(ownerId).set({
        stripeAccountId: accountId,
        email: email,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        onboarded: false,
      }, {merge: true});

      console.log(`Created new account: ${accountId}`);
    }

    // Create account link for onboarding
    const accountLink = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: `https://yourdomain.com/refresh/${ownerId}`,
      return_url: `https://yourdomain.com/return/${ownerId}`,
      type: "account_onboarding",
    });

    return {url: accountLink.url};
  } catch (error) {
    console.error("Error creating connected account:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Webhook to handle Stripe account updates
 */
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  const endpointSecret = functions.config().stripe.webhook_secret;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  } catch (err) {
    console.error("Webhook signature verification failed:", err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  if (event.type === "account.updated") {
    const account = event.data.object;
    const accountId = account.id;

    // Check if charges are enabled
    const chargesEnabled = account.charges_enabled;
    const detailsSubmitted = account.details_submitted;

    if (chargesEnabled && detailsSubmitted) {
      // Update Firestore to mark as onboarded
      const providersSnapshot = await admin.firestore()
          .collection("providers")
          .where("stripeAccountId", "==", accountId)
          .get();

      if (!providersSnapshot.empty) {
        const providerDoc = providersSnapshot.docs[0];
        await providerDoc.ref.update({
          onboarded: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Provider ${providerDoc.id} marked as onboarded`);
      }
    }
  }

  res.json({received: true});
});

/**
 * Creates a Payment Intent for booking a scooter
 * Uses Stripe Connect to transfer funds to the scooter owner
 */
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  const {amount, providerId, scooterId} = data;

  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
    );
  }

  try {
    // Get provider's Stripe account ID
    const providerDoc = await admin.firestore()
        .collection("providers")
        .doc(providerId)
        .get();

    if (!providerDoc.exists || !providerDoc.data().stripeAccountId) {
      throw new functions.https.HttpsError(
          "failed-precondition",
          "Provider not onboarded with Stripe"
      );
    }

    const stripeAccountId = providerDoc.data().stripeAccountId;

    // Calculate platform fee (15% of total)
    const platformFeeAmount = Math.round(amount * 0.15);

    // Create Payment Intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: "usd",
      payment_method_types: ["card"],
      application_fee_amount: platformFeeAmount,
      transfer_data: {
        destination: stripeAccountId,
      },
      metadata: {
        customerId: context.auth.uid,
        providerId: providerId,
        scooterId: scooterId,
      },
    });

    // Log the payment intent creation
    await admin.firestore().collection("payment_intents").add({
      paymentIntentId: paymentIntent.id,
      customerId: context.auth.uid,
      providerId: providerId,
      scooterId: scooterId,
      amount: amount,
      platformFee: platformFeeAmount,
      status: paymentIntent.status,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    };
  } catch (error) {
    console.error("Error creating payment intent:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Webhook to handle successful payments
 */
exports.handleSuccessfulPayment = functions.https.onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  const endpointSecret = functions.config().stripe.webhook_secret;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  } catch (err) {
    console.error("Webhook signature verification failed:", err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle successful payment
  if (event.type === "payment_intent.succeeded") {
    const paymentIntent = event.data.object;

    try {
      // Update payment intent status in Firestore
      const paymentIntentsSnapshot = await admin.firestore()
          .collection("payment_intents")
          .where("paymentIntentId", "==", paymentIntent.id)
          .get();

      if (!paymentIntentsSnapshot.empty) {
        const paymentIntentDoc = paymentIntentsSnapshot.docs[0];
        await paymentIntentDoc.ref.update({
          status: "succeeded",
          succeededAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Get metadata
        const metadata = paymentIntent.metadata;

        // Create booking confirmation
        await admin.firestore().collection("booking_confirmations").add({
          paymentIntentId: paymentIntent.id,
          customerId: metadata.customerId,
          providerId: metadata.providerId,
          scooterId: metadata.scooterId,
          amount: paymentIntent.amount,
          confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Payment confirmed for scooter ${metadata.scooterId}`);
      }
    } catch (error) {
      console.error("Error handling successful payment:", error);
    }
  }

  res.json({received: true});
});

