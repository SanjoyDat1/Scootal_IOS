//
//  SwiftUIView.swift
//  Scootal
//
//  Created by Sanjoy Datta on 2025-04-10.
//

import FirebaseFunctions
import Foundation
import UIKit

var functions = Functions.functions()

func onboardProvider(email: String) {
  functions.httpsCallable("createConnectedAccount").call(["email": email]) { result, error in
    if let error = error {
      print("Error: \(error.localizedDescription)")
      return
    }
    guard let urlString = (result?.data as? [String: Any])?["url"] as? String,
          let url = URL(string: urlString) else { return }
    UIApplication.shared.open(url)
  }
}
