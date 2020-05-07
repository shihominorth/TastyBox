//
//  EmailLoginViewController.swift
//  Recipe-CICCC
//
//  Created by Argus Chen on 2020-01-20.
//  Copyright © 2020 Argus Chen. All rights reserved.
//

import Foundation
import Firebase
import FBSDKLoginKit
import GoogleSignIn
import AuthenticationServices
import CryptoKit

class LoginMainpageViewController: UIViewController {
    
    var userImage: UIImage = #imageLiteral(resourceName: "imageFile")
    
    let vc =  UIStoryboard(name: "AboutPage", bundle: nil).instantiateViewController(withIdentifier: "about") as! AboutViewController
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var login: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        view.backgroundColor = #colorLiteral(red: 0.9977325797, green: 0.9879661202, blue: 0.7689270973, alpha: 1)
        view.tag = 100
        
        let  indicator = UIActivityIndicatorView()
        indicator.transform = CGAffineTransform(scaleX: 2, y: 2)
        
        indicator.color = .orange
        indicator.startAnimating()
        
        view.addSubview(indicator)
        indicator.center = self.view.center
        
        
        self.view.addSubview(view)
        
        if Auth.auth().currentUser != nil {
            // User is signed in.
            
            let Storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = Storyboard.instantiateViewController(withIdentifier: "Discovery")
            self.navigationController?.pushViewController(vc, animated: true)
            
        } else {
            if let viewWithTag = self.view.viewWithTag(100) {
                viewWithTag.removeFromSuperview()
            }else{
                print("No!")
            }
            
        }
        
        roundCorners(view: login, cornerRadius: 5.0)
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        // Do any additional setup after loading the view.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
        
        self.navigationItem.hidesBackButton = true;
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func unwindtoLoginMain(segue: UIStoryboardSegue) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: Email login
    @IBAction func loginAction(_ sender: Any) {
        
        if self.emailTextField.text == "" || self.passwordTextField.text == "" {
            //mention that they didn't insert the text field
            let alertController = UIAlertController(title: "Error", message: "Please enter your email and password", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
        } else {
            Auth.auth().signIn(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!) {
                (user, error) in
                
                if let error = error {
                    let alertController = UIAlertController(title: "Login Error", message:error.localizedDescription, preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(okayAction)
                    self.present(alertController, animated: true, completion: nil)
                    return
                }
                
                guard let currentUser = Auth.auth().currentUser, currentUser.isEmailVerified else {
                    let alertController = UIAlertController(title: "Login Error", message:"You haven't confirmed your email address yet. We sent you a confirmation email when you sign up. Please click the verification link in that email. If you need us to send the confirmation email again, please tap Resend Email.", preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "Resend email", style: .default,handler: { (action) in
                        Auth.auth().currentUser?.sendEmailVerification(completion: nil)
                    })
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    alertController.addAction(okayAction)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion: nil)
                    return
                }
                self.view.endEditing(true)
                self.passwordTextField.text = ""
                
                if  (user?.additionalUserInfo!.isNewUser)! {
                    
                    self.vc.isFirst = true
                    self.navigationController?.pushViewController(self.vc, animated: true)
                    
                } else {
                    Firestore.firestore().collection("user").document(Auth.auth().currentUser!.uid).addSnapshotListener { data, error in
                        if let error = error {
                            print(error.localizedDescription)
                        } else {
                            
                            if let data = data {
                                let isFirst = data["isFirst"] as? Bool
                                if let isFirst = isFirst {
                                    if isFirst == true {
                                        self.vc.isFirst = true
                                        self.navigationController?.pushViewController(self.vc, animated: true)
                                        
                                    } else {
                                        self.vc.isFirst = false
                                        let Storyboard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
                                        let vc = Storyboard.instantiateViewController(withIdentifier: "FirstTimeProfile")
                                        self.navigationController?.pushViewController(vc, animated: true)
                                    }
                                } else {
                                    self.vc.isFirst = true
                                    self.navigationController?.pushViewController(self.vc, animated: true)
                                }
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
    //MARK: Facebook Login
    @IBAction func facebookLogin(_ sender: UIButton) {
        let fbLoginManager = LoginManager()
        fbLoginManager.logIn(permissions: ["public_profile", "email"], from: self) {(
            Result, Error) in
            if let error = Error {
                print("Failed to login: \(error.localizedDescription)")
                return
            }
            
            guard let accessToken = AccessToken.current
                else {
                    print("Failed to get access token")
                    return
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
            
            // call Firebase API to signin
            Auth.auth().signIn(with: credential, completion: { user, error in
                if let error = error {
                    print("Login error: \(error.localizedDescription)")
                    let alertController = UIAlertController(title: "Login error", message: error.localizedDescription, preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(okayAction)
                    self.present(alertController, animated: true, completion: nil)
                    
                    return
                }
                
                // present the main View
                if error == nil {
                    
                    if  (user?.additionalUserInfo!.isNewUser)! {
                        
                        self.vc.isFirst = true
                        self.navigationController?.pushViewController(self.vc, animated: true)
                        
                    } else {
                        Firestore.firestore().collection("user").document(Auth.auth().currentUser!.uid).addSnapshotListener { data, error in
                            if let error = error {
                                print(error.localizedDescription)
                            } else {
                                
                                if let data = data {
                                    let isFirst = data["isFirst"] as? Bool
                                    if let isFirst = isFirst {
                                        if isFirst == true {
                                            self.vc.isFirst = true
                                            self.navigationController?.pushViewController(self.vc, animated: true)
                                            
                                        } else {
                                            self.vc.isFirst = false
                                            let Storyboard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
                                            let vc = Storyboard.instantiateViewController(withIdentifier: "FirstTimeProfile")
                                            self.navigationController?.pushViewController(vc, animated: true)
                                        }
                                    } else {
                                        self.vc.isFirst = true
                                        self.navigationController?.pushViewController(self.vc, animated: true)
                                    }
                                }
                                
                            }
                        }
                    }
                }
            })
        }
    }
    
    
    

    //MARK: keyboard delegate
    @objc func keyboardWillShow(notification: NSNotification) {
        if ((notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= 100
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    //MARK: Apple login
     
     // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
     private func randomNonceString(length: Int = 32) -> String {
         precondition(length > 0)
         let charset: Array<Character> =
             Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
         var result = ""
         var remainingLength = length
         
         while remainingLength > 0 {
             let randoms: [UInt8] = (0 ..< 16).map { _ in
                 var random: UInt8 = 0
                 let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                 if errorCode != errSecSuccess {
                     fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                 }
                 return random
             }
             
             randoms.forEach { random in
                 if length == 0 {
                     return
                 }
                 
                 if random < charset.count {
                     result.append(charset[Int(random)])
                     remainingLength -= 1
                 }
             }
         }
         
         return result
     }
     
     // Unhashed nonce.
     fileprivate var currentNonce: String?
     
     @available(iOS 13, *)
     func startSignInWithAppleFlow() {
         let nonce = randomNonceString()
         currentNonce = nonce
         let appleIDProvider = ASAuthorizationAppleIDProvider()
         let request = appleIDProvider.createRequest()
         request.requestedScopes = [.fullName, .email]
         request.nonce = sha256(nonce)
         
         let authorizationController = ASAuthorizationController(authorizationRequests: [request])
         authorizationController.delegate = self
        authorizationController.presentationContextProvider = self as! ASAuthorizationControllerPresentationContextProviding
         authorizationController.performRequests()
     }
     
     @available(iOS 13, *)
     private func sha256(_ input: String) -> String {
         let inputData = Data(input.utf8)
         let hashedData = SHA256.hash(data: inputData)
         let hashString = hashedData.compactMap {
             return String(format: "%02x", $0)
         }.joined()
         
         return hashString
     }

}

extension LoginMainpageViewController: ASAuthorizationControllerDelegate {

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
      guard let nonce = currentNonce else {
        fatalError("Invalid state: A login callback was received, but no login request was sent.")
      }
      guard let appleIDToken = appleIDCredential.identityToken else {
        print("Unable to fetch identity token")
        return
      }
      guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
        print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
        return
      }
      // Initialize a Firebase credential.
      let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com",
                                                idToken: idTokenString,
                                                rawNonce: nonce)
    
        UserDefaults.standard.set(appleIDCredential.user, forKey: "appleAuthorizedUserIdKey")

      // Sign in with Firebase.
      Auth.auth().signIn(with: firebaseCredential) { (authResult, error) in
        if (error != nil) {
          // Error. If error.code == .MissingOrInvalidNonce, make sure
          // you're sending the SHA256-hashed nonce as a hex string with
          // your request to Apple.
            print(error?.localizedDescription)
          return
        }
        // User is signed in to Firebase with Apple.
        // ...
      }
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    // Handle error.
    print("Sign in with Apple errored: \(error)")
  }

}


//MARK: Google login
extension LoginMainpageViewController: GIDSignInDelegate {
    
    //MARK: Google login
    @IBAction func googleLogin(sender: UIButton) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            return
        }
        guard let authentication = user.authentication else {
            return
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        
        Auth.auth().signIn(with: credential, completion: { (user, error) in
            if let error = error {
                print("Login error: \(error.localizedDescription)")
                let alertController = UIAlertController(title: "Login Error", message: error.localizedDescription, preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(okayAction)
                self.present(alertController, animated: true, completion: nil)
                return
            }
            // present the main view
            if error == nil {
                
                if  (user?.additionalUserInfo!.isNewUser)! {
                    
                    self.vc.isFirst = true
                    self.navigationController?.pushViewController(self.vc, animated: true)
                    
                } else {
                    
                    if  (user?.additionalUserInfo!.isNewUser)! {
                        
                        self.vc.isFirst = true
                        self.navigationController?.pushViewController(self.vc, animated: true)
                        
                    } else {
                        Firestore.firestore().collection("user").document(Auth.auth().currentUser!.uid).addSnapshotListener { data, error in
                            if let error = error {
                                print(error.localizedDescription)
                            } else {
                                
                                if let data = data {
                                    let isFirst = data["isFirst"] as? Bool
                                    if let isFirst = isFirst {
                                        if isFirst == true {
                                            self.vc.isFirst = true
                                            self.navigationController?.pushViewController(self.vc, animated: true)
                                            
                                        } else {
                                            
                                            UIView.animate(withDuration: 1.0) {
                                                self.vc.isFirst = false
                                                let Storyboard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
                                                let vc = Storyboard.instantiateViewController(withIdentifier: "FirstTimeProfile")
                                                self.navigationController?.pushViewController(vc, animated: true)
                                            }
                                        }
                                    } else {
                                        self.vc.isFirst = true
                                        self.navigationController?.pushViewController(self.vc, animated: true)
                                    }
                                }
                                
                            }
                        }
                    
                    
                }
            }
            }
        })
        
    }
    
  
    
}

extension LoginMainpageViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        switch textField.tag {
        case 1:
            // they work
            emailTextField.resignFirstResponder()
            passwordTextField.becomeFirstResponder()
            break
        case 2:
            // not close the keyboard
            textField.resignFirstResponder()
            break
        default:
            break
        }
        return true
    }
    
}

extension LoginMainpageViewController{
    func roundCorners(view: UIView, cornerRadius: Double) {
        view.layer.cornerRadius = CGFloat(cornerRadius)
        view.clipsToBounds = true
    }
}

