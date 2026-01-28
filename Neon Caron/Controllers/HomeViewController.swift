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
    
    // El botón ya está configurado en el Storyboard, pero podemos personalizarlo aquí si es necesario
    // createCollectionButton ya tiene el título "Create Collection +" desde el Storyboard
  }
  
  @IBAction func createCollectionTapped(_ sender: UIButton) {
    // Por ahora, mostrar una alerta temporal
    // En fases posteriores, abriremos la pantalla de crear colección
    let alert = UIAlertController(
      title: "Create Collection",
      message: "Esta funcionalidad estará disponible pronto!",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
  
  private func configureTableView() {
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(UINib(nibName: "HomeTableCell", bundle: nil), forCellReuseIdentifier: "HomeTableCell")
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 124
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let destinationVC = segue.destination as! ViewController
    destinationVC.collectionName = collectionName
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
