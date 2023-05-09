import UIKit

extension UIImageView {
    
    func RoundedImage() {
        self.layer.cornerRadius = self.frame.size.width / 2
        self.clipsToBounds = true
        self.contentMode = .scaleAspectFill
    }
}

extension UIImage {
    func center_crop(to size: Int) -> UIImage? {
        guard let imageRef = self.cgImage?.cropping(to: CGRect(x: Int(self.size.width) / 2 - size / 2, y: Int(self.size.height) / 2 - size / 2, width: size, height: size)) else {
            return nil
        }
        let croppedImage = UIImage(cgImage: imageRef)
        return croppedImage
    }
}

class SettingsController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var log_out_button: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    let tapGesture = UITapGestureRecognizer()
    override func loadView() {
        super.loadView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imageView.RoundedImage()
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)
        imageView.image = User.main_user?.avatar
        tapGesture.addTarget(self, action: #selector(SelectImage))
        
    }

    @objc func SelectImage() {
        // Открываем контроллер выбора изображения
        imagePicker.sourceType = .photoLibrary // выбор из галереи
        // imagePicker.sourceType = .camera // выбор с камеры
        present(imagePicker, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Загружаем выбранное изображение в imageView
        guard let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        User.main_user?.avatar = selectedImage
        imageView.image = selectedImage.center_crop(to: 4 * Int(imageView.frame.size.width))
        // Закрываем контроллер выбора изображения
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Закрываем контроллер выбора изображения без выбора изображения
        dismiss(animated: true, completion: nil)
    }
    @IBAction func LogOut(_ sender: Any) {
        UserExit()
        
//        routes_lock.lock()
//        routes_to_draw_lock.lock()
//
//        routes.removeAll()
//        routes_to_draw.removeAll()
//
//        routes_lock.unlock()
//        routes_to_draw_lock.unlock()
        
        let reg_storyboard = UIStoryboard(name: "Login", bundle: nil)
        let reg_controller = reg_storyboard.instantiateViewController(withIdentifier: "Login") as! LoginController
        reg_controller.modalPresentationStyle = .fullScreen
        self.present(reg_controller, animated: true)
        
//        self.dismiss(animated: true, completion: nil)

//        UIApplication.shared.windows.first?.rootViewController = reg_controller
//        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
}

