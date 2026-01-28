//
//  HomeViewController.swift
//  Neon Caron
//
//  Created by Pablo Ruiz on 10/10/20.
//

import Foundation
import UIKit

class HomeViewController: UIViewController {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var greetingLabel: UILabel!
  @IBOutlet weak var createCollectionButton: UIButton!
  
  let paintingCollections = PaintingCollections()
  var collectionName = ""
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureTableView()
    setupHeaderUI()
    navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
    navigationController?.navigationBar.shadowImage = UIImage()
    navigationController?.navigationBar.isTranslucent = true
  }
  
  private func setupHeaderUI() {
    // Configurar el saludo (por ahora estático, en Fase 2 cambiará según login)
    greetingLabel.text = "Hello, stranger"
    
    // Hacer el label táctil para navegar al login
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(greetingLabelTapped))
    greetingLabel.isUserInteractionEnabled = true
    greetingLabel.addGestureRecognizer(tapGesture)
    
    // El botón ya está configurado en el Storyboard, pero podemos personalizarlo aquí si es necesario
    // createCollectionButton ya tiene el título "Create Collection +" desde el Storyboard
  }
  
  @objc private func greetingLabelTapped() {
    performSegue(withIdentifier: "HomeToLogin", sender: self)
  }
  
  @IBAction func createCollectionTapped(_ sender: UIButton) {
    // Navegar al LoginViewController cuando se toca "Create Collection +"
    performSegue(withIdentifier: "HomeToLogin", sender: self)
  }
  
  private func configureTableView() {
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(UINib(nibName: "HomeTableCell", bundle: nil), forCellReuseIdentifier: "HomeTableCell")
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 124
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // Solo preparar datos si es el segue hacia AR ViewController
    if segue.identifier == "HomeToAR" {
      if let destinationVC = segue.destination as? ViewController {
        destinationVC.collectionName = collectionName
      }
    }
    // Para otros segues (como HomeToLogin), no necesitamos preparar datos
  }
}

extension HomeViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    collectionName = paintingCollections.categoryNames[indexPath.row].name
    performSegue(withIdentifier: "HomeToAR", sender: self)
  }
}

extension HomeViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return paintingCollections.categoryNames.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "HomeTableCell", for: indexPath) as! HomeTableCell
    let category = paintingCollections.categoryNames[indexPath.row]
    cell.configure(with: category.displayName, image: UIImage(named: category.image))
    return cell
  }
    
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0
  }
}
