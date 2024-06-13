//
//  ViewController.swift
//  Neon Caron
//
//  Created by Pablo Ruiz on 10/10/20.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
  
  @IBOutlet var sceneView: ARSCNView!
  var collectionName: String = "neon";
  let cacheVideosDirName = "neonVideos"
  let paintingCollections = PaintingCollections()
  private let downloadManager = SDDownloadManager.shared
  var videoPlayers: [String: AVPlayer] = [:]
  var nodesUsingLocalFiles: [String] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Set the view's delegate
    sceneView.delegate = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Create a session configuration
    let configuration = ARImageTrackingConfiguration()
    
    // first see if there is a folder called "ARImages" Resource Group in our Assets Folder
    if let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: collectionName, bundle: Bundle.main) {
      
      // if there is, set the images to track
      configuration.trackingImages = trackedImages
      // at any point in time, only 1 image will be tracked
      configuration.maximumNumberOfTrackedImages = 4
    }
    
    // Run the view's session
    sceneView.session.run(configuration)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Pause the view's session
    sceneView.session.pause()
  }
  
  func getDownloadedVideoURL(name: String) -> URL? {
    guard let localURL = SDFileUtils.getCacheFileURL(fineName: name, directory: cacheVideosDirName) else {
      return nil
    }
    return localURL
  }
  
  private func downloadFile(url: URL) {
    let request = URLRequest(url: url)
    let fileName = url.lastPathComponent
    _ = downloadManager.downloadFile(
      withRequest: request,
      inDirectory: cacheVideosDirName,
      withName: fileName,
      shouldDownloadInBackground: true,
      onCompletion: { (error, localURL) in
        if let error = error {
          print("Error is \(error as NSError)")
        } else if let localURL = localURL {
          print("Downloaded file's url is \(localURL.path)")
        }
      })
  }
  
  // MARK: - ARSCNViewDelegate
  
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    
    // if the anchor is not of type ARImageAnchor (which means image is not detected), just return
    guard let anchorName = anchor.name, let names = anchor.name?.split(separator: "_"), names.count == 2 else {
      return
    }
    guard let imageAnchor = anchor as? ARImageAnchor,
          let videoUrl = paintingCollections.collections[collectionName]?[String(names[1])],
          let url = URL(string: videoUrl) else {return}
    
    var player: AVPlayer!
    var videoItem: AVPlayerItem!
    let fileName = url.lastPathComponent
    if let localURL = getDownloadedVideoURL(name: fileName) {
      videoItem = AVPlayerItem(url: localURL)
      player = AVPlayer(playerItem: videoItem)
      nodesUsingLocalFiles.append(anchor.name ?? "")
    } else {
      videoItem = CachingPlayerItem(url: url)
//      videoItem.delegate = self
//      videoItem.preferredForwardBufferDuration = TimeInterval(4)
//      videoItem = AVPlayerItem(url: url)
      player = AVPlayer(playerItem: videoItem)
      downloadFile(url: url)
    }
    
    videoPlayers[anchorName] = player
    //find our video file
    let videoNode = SKVideoNode(avPlayer: player)
    player.automaticallyWaitsToMinimizeStalling = false
    player.play()
    // add observer when our player.currentItem finishes player, then start playing from the beginning
    addFinishedPlayingObserver(player: player, videoItem: videoItem, fileName: fileName, targetName: anchor.name ?? "")
    // set the size (just a rough one will do)
    let videoScene = SKScene(size: CGSize(width: 480, height: 360))
    // center our video to the size of our video scene
    videoNode.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
    videoNode.size = CGSize(width: videoScene.size.width, height: videoScene.size.height)
    videoNode.zPosition = 500
    // invert our video so it does not look upside down
    videoNode.yScale = -1.0
    // add the video to our scene
    videoScene.addChild(videoNode)
    // create a plan that has the same real world height and width as our detected image
    let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
    // set the first materials content to be our video scene
    plane.firstMaterial?.diffuse.contents = videoScene
    // create a node out of the plane
    let planeNode = SCNNode(geometry: plane)
    // since the created node will be vertical, rotate it along the x axis to have it be horizontal or parallel to our detected image
    planeNode.eulerAngles.x = -Float.pi / 2
    // finally add the plane node (which contains the video node) to the added node
    node.addChildNode(planeNode)
  }
  
  private func addFinishedPlayingObserver(player: AVPlayer, videoItem: AVPlayerItem, fileName: String, targetName: String) {
    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: videoItem, queue: nil) { [weak self] (notification) in
      guard let `self` = self else {return}
      if !self.nodesUsingLocalFiles.contains(targetName), let localURL = self.getDownloadedVideoURL(name: fileName) {
        let localVideoItem = AVPlayerItem(url: localURL)
        player.replaceCurrentItem(with: localVideoItem)
        self.nodesUsingLocalFiles.append(targetName)
        self.addFinishedPlayingObserver(player: player, videoItem: localVideoItem, fileName: fileName, targetName: targetName)
      }
      player.seek(to: CMTime.zero)
      player.play()
    }
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    if let anchorName = anchor.name, let player = videoPlayers[anchorName]{
      let action = node.isHidden ? { player.pause() } : { player.play() }
      action()
    }
  }
  
  func session(_ session: ARSession, didFailWithError error: Error) {
    // Present an error message to the user
    print("didFailWithError")
  }
  
  func sessionWasInterrupted(_ session: ARSession) {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    print("sessionWasInterrupted")
  }
  
  func sessionInterruptionEnded(_ session: ARSession) {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    print("sessionInterruptionEnded")
  }
}

extension ViewController: CachingPlayerItemDelegate {
  func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
    if let urlAsset = playerItem.asset as? AVURLAsset {
      print(urlAsset.url.absoluteURL)
    }
    print("\(bytesDownloaded)/\(bytesExpected)")
  }
}
