import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  
  let wikipediaURL = "https://en.wikipedia.org/w/api.php"
  let imagePicker = UIImagePickerController()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // hopping into imagePicker delegate
    imagePicker.delegate = self
    
    // allowing picture editing
    imagePicker.allowsEditing = true
    
    // source type for our picker, in this case it's "camera", it could also be a photo library.
    imagePicker.sourceType = .camera
    
  }
  
  // function for the image processing once user chooses "Use Photo" option.
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
    // using the edited (cropped) version of the image that was taken by the user. (or chosen and then edited from the photo library)
    if let userPickedImage = info[.editedImage] as? UIImage {
      guard let convertedCIImage = CIImage(image: userPickedImage) else {
        fatalError("Can not convert to CIImage")
      }
      
      detect(image: convertedCIImage)

    }
    
    
    // dismissing the image view upon next step
    imagePicker.dismiss(animated: true,completion: nil)
  }
  
  func detect(image: CIImage) {
    
    guard let model = try? VNCoreMLModel(for: Oxford102().model) else {
      fatalError("Can not import model")
    }
    let request = VNCoreMLRequest(model: model) { (request, error) in
      guard let classification = request.results?.first as? VNClassificationObservation else {
        fatalError("Could not classify the image.")
      }
      
      self.navigationItem.title = classification.identifier.capitalized
      
      self.requestInfo(flowerName: classification.identifier)
      
    }
    let handler = VNImageRequestHandler(ciImage: image)
    do {
      try  handler.perform([request])
    } catch {
      print(error)
    }
    
  }
  
  func requestInfo(flowerName: String) {
    
    let parameters: [String:String] = [
      "format" : "json",
      "action" : "query",
      "prop" : "extracts|pageimages",
      "exintro" : "",
      "explaintext" : "",
      "titles" : flowerName,
      "indexpageids" : "",
      "redirects" : "1",
      "pithumbsize" : "500"
    ]
    
    Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
      if response.result.isSuccess {
        
        print("Got the wikipedia info.")
        print(response)
        
        let flowerJSON: JSON = JSON(response.result.value!)
        
        let pageid = flowerJSON["query"]["pageids"][0].stringValue
        
        let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue

        let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue

        self.imageView.sd_setImage(with: URL(string: flowerImageURL))
        self.label.text = flowerDescription
      }
    }
  }
  
  // what happens when camera button is pressed
  @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
    // presenting the imagePicker to take a picture in this case.
    present(imagePicker, animated: true, completion: nil)
  }
  
}

