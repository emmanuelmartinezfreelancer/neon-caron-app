//
//  LoginViewController.swift
//  Neon Caron
//
//  Created for User Collections feature
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var gmailSignInButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Access your account"
        emailTextField.placeholder = "Email"
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        gmailSignInButton.setTitle("Sign in with Gmail", for: .normal)
        loginButton.setTitle("Log In", for: .normal)
        signUpLabel.text = "Don't have an account? Sign up for create custom collections."
        signUpLabel.textAlignment = .center
        signUpLabel.numberOfLines = 0
        
        // Hacer el label de sign up táctil
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(signUpLabelTapped))
        signUpLabel.isUserInteractionEnabled = true
        signUpLabel.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func gmailSignInTapped(_ sender: UIButton) {
        // Por ahora mostrar alerta, en Fase 2 se integrará con Cognito
        showComingSoonAlert()
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter email and password")
            return
        }
        
        // Por ahora mostrar alerta, en Fase 2 se integrará con Cognito
        showComingSoonAlert()
    }
    
    @objc private func signUpLabelTapped() {
        showComingSoonAlert()
    }
    
    private func showComingSoonAlert() {
        showAlert(title: "Feature Coming Soon", message: "This feature will be available soon!")
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
