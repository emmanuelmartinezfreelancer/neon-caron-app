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
    
    print("🔍 [DEBUG] renderer didAdd called - collectionName: \(collectionName)")
    
    // if the anchor is not of type ARImageAnchor (which means image is not detected), just return
    guard let anchorName = anchor.name, let names = anchor.name?.split(separator: "_"), names.count == 2 else {
      print("❌ [DEBUG] Invalid anchor name format: \(anchor.name ?? "nil")")
      return
    }
    
    print("✅ [DEBUG] Anchor name parsed: \(anchorName), collection: \(String(names[0])), image: \(String(names[1]))")
    
    guard let imageAnchor = anchor as? ARImageAnchor,
          let videoUrl = paintingCollections.collections[collectionName]?[String(names[1])],
          let url = URL(string: videoUrl) else {
      print("❌ [DEBUG] Failed to get video URL for: \(collectionName)/\(String(names[1]))")
      return
    }
    
    print("✅ [DEBUG] Video URL found: \(videoUrl)")
    
    var player: AVPlayer!
    var videoItem: AVPlayerItem!
    let fileName = url.lastPathComponent
    print("📥 [DEBUG] Loading video: \(fileName)")
    
    if let localURL = getDownloadedVideoURL(name: fileName) {
      print("✅ [DEBUG] Using cached video: \(localURL.path)")
      videoItem = AVPlayerItem(url: localURL)
      player = AVPlayer(playerItem: videoItem)
      nodesUsingLocalFiles.append(anchor.name ?? "")
    } else {
      print("🌐 [DEBUG] Streaming video from URL: \(url.absoluteString)")
      videoItem = CachingPlayerItem(url: url)
      player = AVPlayer(playerItem: videoItem)
      downloadFile(url: url)
    }
    
    videoPlayers[anchorName] = player
    print("✅ [DEBUG] Player created and stored for: \(anchorName)")
    player.automaticallyWaitsToMinimizeStalling = false
    
    // add observer when our player.currentItem finishes player, then start playing from the beginning
    addFinishedPlayingObserver(player: player, videoItem: videoItem, fileName: fileName, targetName: anchor.name ?? "")
    
    // create a plan that has the same real world height and width as our detected image
    let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
    let material = plane.firstMaterial!
    
    // iOS 13.4+ supports HEVC with alpha directly - use AVPlayer directly (no SKVideoNode)
    if collectionName == "experimental" {
        print("✨ [DEBUG] Using direct AVPlayer for experimental video (iOS 13.4+ alpha support)")
        // Direct assignment - SceneKit handles alpha channel automatically
        material.diffuse.contents = player
        print("✅ [DEBUG] AVPlayer assigned directly to material - alpha channel supported natively")
    } else {
        print("📹 [DEBUG] Using SKVideoNode for regular video: \(collectionName)")
        // For non-experimental, use original SKVideoNode approach
        let videoNode = SKVideoNode(avPlayer: player)
        let videoScene = SKScene(size: CGSize(width: 480, height: 360))
        videoNode.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
        videoNode.size = CGSize(width: videoScene.size.width, height: videoScene.size.height)
        videoNode.zPosition = 500
        videoNode.yScale = -1.0
        videoScene.addChild(videoNode)
        material.diffuse.contents = videoScene
    }
    
    // Start playing
    player.play()
    print("✅ [DEBUG] Video playback started")
    
    // create a node out of the plane
    let planeNode = SCNNode(geometry: plane)
    // since the created node will be vertical, rotate it along the x axis to have it be horizontal or parallel to our detected image
    planeNode.eulerAngles.x = -Float.pi / 2
    // finally add the plane node (which contains the video node) to the added node
    node.addChildNode(planeNode)
    print("✅ [DEBUG] Plane node added to scene - Video should be playing now")
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
    print("❌ [DEBUG] AR Session failed with error: \(error.localizedDescription)")
    print("❌ [DEBUG] Error details: \(error)")
  }
  
  func sessionWasInterrupted(_ session: ARSession) {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    print("⚠️ [DEBUG] AR Session was interrupted")
  }
  
  func sessionInterruptionEnded(_ session: ARSession) {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    print("✅ [DEBUG] AR Session interruption ended")
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
