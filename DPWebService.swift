

import Foundation
import UIKit
import SystemConfiguration

class DPWebService: NSObject {
    
    fileprivate static let noInternet = "No internet connection was found. please try again later"
    fileprivate static let noConnection = "Cannot connect to server"
    //Specify your APIURl in baseURL
    fileprivate static let baseUrl = ""
    
    
    enum DPMethod : String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case PATCH = "PATCH"
        case DELETE = "DELETE"
        case COPY = "COPY"
        case HEAD = "HEAD"
        case OPTIONS = "OPTIONS"
        case LINK = "LINK"
        case UNLINK = "UNLINK"
        case PURGE = "PURGE"
        case LOCK = "LOCK"
        case UNLOCK = "UNLOCK"
    }
    
    
    /*
     1. View - if you pass view object than its show Indicater(loader)
     
     2. isUserInteractionEnabled if you pass true than view user inraction is enble if you pass false than view intraction disble true for (listing api) false for (login,signup, payment etc)
     
     3. api :- pass only last componant of api
     
     4. body :- parameter if not any parameter than pass nil
     
     5. returnFailedBlock :- it you pass false than error popup display ("no data found") no call back for status == false
     if you need to display data for failed staus than you must be pass true
     */
    
    class open func DPService (methodName:DPMethod, view:UIView?, isUserInteractionEnabled:Bool, returnFailedBlock:Bool,  api:String,message:String, body:NSMutableDictionary?,Hendler complition:@escaping (_ JSON:NSDictionary,_ status:Int,_ message:String) -> Void) {
        
        
        if InternetCheck() == false {
            if returnFailedBlock == true {
                complition([:],-5,noInternet)
                return
            }
            UIAlertController.showAlertError(message:noInternet)
            return
        }
        
        let url = NSURL(string:"\(self.baseUrl)"  + api)
        if url == nil {
            UIAlertController.showAlertError(message: "Please check URL its Just for Development")
            return
        }
        
        var request = NSMutableURLRequest(url: url! as URL)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)        //session.delegate = self
        request.httpMethod = methodName.rawValue
        request.addValue("bb0817d0bd9a90fcad71d85391bc946b", forHTTPHeaderField: "AuthToken")
        request = DPWebService.header(request: request)
        
        let apibody = DPWebService.getBody(body: body)
        if DPWebService.checkMultipart(apibody) {
            //            request = self.multiPart(request: request, apibody: apibody)
        }else{
            let apiParameter = DPWebService.stringFromDictionart(apibody: apibody)
            request.httpBody = apiParameter.data(using: String.Encoding.utf8.rawValue)
        }
        
        if view != nil  {
            
            DPLoader.show(InView:view, message)
        }
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            
            DispatchQueue.main.async {
                
                if view != nil  {
                    
                    DPLoader.dismiss(InView:view)
                }
                
                if data != nil {
                    let strData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                    print("method : \(methodName)")
                    print("Url: \(self.baseUrl)" + api)
                    print("Body: \(apibody)" )
                    print("Responcse : \(strData!)")
                    
                    do {
                        if  let JSON = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                            
                            if let status = JSON["code"] as? NSNumber {
                                
                                var message = "No message from Searver side"
                                if let msg  = JSON["message"] as? String{
                                    message = msg
                                }
                                
                                if status == 200{
                                    complition(JSON,200,message)
                                    return
                                }else{
                                    
                                    if returnFailedBlock == true {
                                        
                                        complition(JSON,400,message)
                                        return
                                    }
                                    UIAlertController.showAlertError(message:message)
                                    
                                }
                                
                            }
                        }
                    } catch {
                        if returnFailedBlock == true {
                            complition([:],403,"Please contact to admin data is not in proper formate")
                            return
                        }
                        UIAlertController.showAlertError(message:"Please contact to admin data is not in proper formate")
                    }
                }else{
                    if returnFailedBlock == true {
                        complition([:],404,self.noConnection)
                        return
                    }
                    
                    // print(error!.localizedDescription)
                    UIAlertController.showAlertError(message: self.noConnection)
                    
                }
                
                
            }
            
        })
        task.resume()
        
    }
    
    
    //    fileprivate class  func multiPart(request:NSMutableURLRequest,apibody:NSMutableDictionary) -> NSMutableURLRequest {
    //
    //        let boundary = "---------------------------14737809831466499882746641449"
    //        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    //
    //        let body = NSMutableData()
    //
    //        for key in apibody.allKeys{
    //
    //            if apibody[key as! String]!  is NSString{
    //
    //                body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
    //                body.append("Content-Disposition:form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
    //                body.append("\(apibody[key as! String]!)\r\n".data(using: String.Encoding.utf8)!)
    //
    //            }
    //            else if apibody[key as! String]!  is NSNumber{
    //
    //                body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
    //                body.append("Content-Disposition:form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
    //                body.append("\(apibody[key as! String]!)\r\n".data(using: String.Encoding.utf8)!)
    //
    //            }
    //            else if apibody[key as! String]! is UIImage{
    //                let img = apibody[key as! String] as! UIImage
    //                let imageData = img.jpegData(compressionQuality: 1.0)
    //                    //UIImageJPEGRepresentation(apibody[key as! String] as! UIImage, 0.3)
    //                // print("imageSize = \((imageData! as NSData).length/1024)")
    //                if imageData == nil {
    //                    break;
    //                }
    //                body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
    //                body.append("Content-Disposition:form-data; name=\"\(key)\"; filename=\"a.jpg\"\r\n".data(using: String.Encoding.utf8)!)
    //                body.append("Content-Type: \("image/jpeg")\r\n\r\n".data(using: String.Encoding.utf8)!)
    //                body.append(imageData!)
    //                body.append("\r\n".data(using: String.Encoding.utf8)!)
    //
    //            }
    //
    //        }
    //
    //
    //        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
    //        request.httpBody = body as Data
    //        return request
    //
    //    }
    
    class func webServiceDataTask(){
        
    }
    
    class  func header(request:NSMutableURLRequest) -> NSMutableURLRequest {
        
        let authStr: String = "\("pnp"):\("api@pnp")"
        let authData = authStr.data(using: String.Encoding.utf8)
        let authValue: String? = "Basic \(authData!.base64EncodedString())"
        request.addValue(authValue!, forHTTPHeaderField: "Authorization")
        return request
    }
    
    class func getBody(body:NSMutableDictionary?) -> NSMutableDictionary{
        
        var apibody:NSMutableDictionary!
        if body == nil {
            apibody = NSMutableDictionary()
        }else{
            apibody = body!.mutableCopy() as! NSMutableDictionary
        }
        
        //Put Extra Common parameter here
        return apibody
    }
    
    
    
    class func stringFromDictionart(apibody:NSMutableDictionary) -> NSMutableString {
        
        let  apiParameter = NSMutableString()
        for key in apibody.allKeys {
            if apiParameter.length != 0{
                apiParameter.append("&")
            }
            if apibody[key as! String]! is NSString {
                
                let str = apibody.value(forKey: key as! String)! as! String
                apibody[key as! String] = str.replacingOccurrences(of: "&", with: "%26")
            }else  if apibody[key as! String]! is NSNumber {
                
                
                apibody[key as! String] = "\(apibody.value(forKey: key as! String)!)"
            }
            
            apiParameter.append("\(key)=\(apibody[key as! String]!)")
            
        }
        return apiParameter
    }
    
    private  class func checkMultipart(_ apibody:NSMutableDictionary) -> Bool {
        
        for key in apibody.allValues
        {
            if key is UIImage || key is URL {
                return true
            }
        }
        return false
    }
    public class func showAlert(_ JSON:NSDictionary)  {
        
        
        var message = "No message from Searver side"
        if let msg  = JSON["message"] as? String{
            message = msg
        }
        UIAlertController.showAlertError(message:message)
        
    }
    
}


//MARK: - FunctionDefination -
func InternetCheck () -> Bool {
    let reachability =  Reachability()
    let networkStatus  = reachability?.currentReachabilityStatus
    if networkStatus == .notReachable {
        return false
    }
    return true
}




//MARK:  - DPLoader Class -

class DPLoader : UIView {
    
    
    let blackView = UIView()
    let lblMessage = UILabel()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let activityIndicater = UIActivityIndicatorView()
        activityIndicater.style = .whiteLarge
        activityIndicater.color = UIColor.white
        activityIndicater.startAnimating()
        
        
        self.lblMessage.textColor = UIColor.white
        self.lblMessage.textAlignment = .center
        self.lblMessage.numberOfLines = 0
        
        self.blackView.translatesAutoresizingMaskIntoConstraints = false
        self.lblMessage.translatesAutoresizingMaskIntoConstraints = false
        activityIndicater.translatesAutoresizingMaskIntoConstraints = false
        
        
        self.addSubview(blackView)
        blackView.addSubview(lblMessage)
        blackView.addSubview(activityIndicater)
        
        
        
        blackView.backgroundColor = UIColor.black
        blackView.layer.cornerRadius = 4
        blackView.layer.masksToBounds = true
        
        
        self.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.2)
        
        
        self.addConstraint(NSLayoutConstraint.init(item: blackView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0))
        
        self.addConstraint(NSLayoutConstraint.init(item: blackView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0))
        
        
        blackView.addConstraint(NSLayoutConstraint.init(item: blackView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem:nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 120))
        
        blackView.addConstraint(NSLayoutConstraint.init(item: blackView, attribute: .width, relatedBy: .greaterThanOrEqual, toItem:nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 120))
        
        blackView.addConstraint(NSLayoutConstraint.init(item: blackView, attribute: .height, relatedBy: .lessThanOrEqual, toItem:nil, attribute: .notAnAttribute, multiplier: 1.0, constant: UIScreen.main.bounds.width - 40))
        
        blackView.addConstraint(NSLayoutConstraint.init(item: blackView, attribute: .width, relatedBy: .lessThanOrEqual, toItem:nil, attribute: .notAnAttribute, multiplier: 1.0, constant: UIScreen.main.bounds.size.width - 40))
        
        
        
        
        
        blackView.addConstraint(NSLayoutConstraint.init(item: activityIndicater, attribute: .centerX, relatedBy: .equal, toItem: blackView, attribute: .centerX, multiplier: 1.0, constant: 0))
        
        blackView.addConstraint(NSLayoutConstraint.init(item: activityIndicater, attribute: .centerY, relatedBy: .equal, toItem: blackView, attribute: .centerY, multiplier: 0.8, constant: 0))
        
        
        blackView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[activityIndicater]-15-[lblMessage]-15-|", options: [], metrics: nil, views: ["lblMessage":lblMessage,"activityIndicater":activityIndicater]))
        
        blackView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[lblMessage]-15-|", options: [], metrics: nil, views: ["lblMessage":lblMessage]))
        
        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    class func show(InView:UIView?, _ message:String){
        
        if InView == nil{
            return
        }
        
        
        guard let loader = InView?.viewWithTag(1322) as? DPLoader else {
            
            let rect = CGRect.init(x: 0, y: 0, width: InView!.frame.width, height: InView!.frame.height)
            let loader = DPLoader.init(frame:rect)
            loader.lblMessage.text = message
            loader.tag = 1322
            InView?.addSubview(loader)
            
            return
        }
        
        
        
        loader.lblMessage.text = message
        loader.tag = 1322
        InView?.addSubview(loader)
        
        
        
        
    }
    
    class func dismiss(InView:UIView?) {
        
        guard let loader = InView?.viewWithTag(1322) as? DPLoader else {return}
        loader.removeFromSuperview()
        
    }
    
    
    
    
    
}





extension UIAlertController {
    
    
    class func showAlertError(message:String){
        
        
        //        AlertBar.show(type: .Custom(#colorLiteral(red: 1, green: 0.5644996166, blue: 0.01918258332, alpha: 1), #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)), message: message)
        
        //                let systemSoundID: SystemSoundID = 1016
        //                AudioServicesPlaySystemSound (systemSoundID)
        //                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        //                let alertController = UIAlertController(title: "", message:message , preferredStyle: .alert)
        //                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        //                alertController.addAction(defaultAction)
        //                appDelegate.window?.rootViewController?.present(alertController, animated: true, completion: nil)
        //
        
        print("set UIAlertController in \(#function)")
        
        
    }
    
    
    
    
    
}




//MARK:  - Reachability Class -

public enum ReachabilityError: Error {
    case FailedToCreateWithAddress(sockaddr_in)
    case FailedToCreateWithHostname(String)
    case UnableToSetCallback
    case UnableToSetDispatchQueue
}

public let ReachabilityChangedNotification = NSNotification.Name("ReachabilityChangedNotification")

func callback(reachability:SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
    
    guard let info = info else { return }
    
    let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
    
    DispatchQueue.main.async {
        reachability.reachabilityChanged()
    }
}

public class Reachability {
    
    public typealias NetworkReachable = (Reachability) -> ()
    public typealias NetworkUnreachable = (Reachability) -> ()
    
    public enum NetworkStatus: CustomStringConvertible {
        
        case notReachable, reachableViaWiFi, reachableViaWWAN
        
        public var description: String {
            switch self {
            case .reachableViaWWAN: return "Cellular"
            case .reachableViaWiFi: return "WiFi"
            case .notReachable: return "No Connection"
            }
        }
    }
    
    public var whenReachable: NetworkReachable?
    public var whenUnreachable: NetworkUnreachable?
    public var reachableOnWWAN: Bool
    
    // The notification center on which "reachability changed" events are being posted
    public var notificationCenter: NotificationCenter = NotificationCenter.default
    
    public var currentReachabilityString: String {
        return "\(currentReachabilityStatus)"
    }
    
    public var currentReachabilityStatus: NetworkStatus {
        guard isReachable else { return .notReachable }
        
        if isReachableViaWiFi {
            return .reachableViaWiFi
        }
        if isRunningOnDevice {
            return .reachableViaWWAN
        }
        
        return .notReachable
    }
    
    fileprivate var previousFlags: SCNetworkReachabilityFlags?
    
    fileprivate var isRunningOnDevice: Bool = {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
        return false
        #else
        return true
        #endif
    }()
    
    fileprivate var notifierRunning = false
    fileprivate var reachabilityRef: SCNetworkReachability?
    
    fileprivate let reachabilitySerialQueue = DispatchQueue(label: "uk.co.ashleymills.reachability")
    
    required public init(reachabilityRef: SCNetworkReachability) {
        reachableOnWWAN = true
        self.reachabilityRef = reachabilityRef
    }
    
    public convenience init?(hostname: String) {
        
        guard let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else { return nil }
        
        self.init(reachabilityRef: ref)
    }
    
    public convenience init?() {
        
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)
        
        guard let ref: SCNetworkReachability = withUnsafePointer(to: &zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else { return nil }
        
        self.init(reachabilityRef: ref)
    }
    
    deinit {
        stopNotifier()
        
        reachabilityRef = nil
        whenReachable = nil
        whenUnreachable = nil
    }
}

public extension Reachability {
    
    // MARK: - *** Notifier methods ***
    func startNotifier() throws {
        
        guard let reachabilityRef = reachabilityRef, !notifierRunning else { return }
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutableRawPointer(Unmanaged<Reachability>.passUnretained(self).toOpaque())
        if !SCNetworkReachabilitySetCallback(reachabilityRef, callback, &context) {
            stopNotifier()
            throw ReachabilityError.UnableToSetCallback
        }
        
        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, reachabilitySerialQueue) {
            stopNotifier()
            throw ReachabilityError.UnableToSetDispatchQueue
        }
        
        // Perform an intial check
        reachabilitySerialQueue.async {
            self.reachabilityChanged()
        }
        
        notifierRunning = true
    }
    
    func stopNotifier() {
        defer { notifierRunning = false }
        guard let reachabilityRef = reachabilityRef else { return }
        
        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }
    
    // MARK: - *** Connection test methods ***
    var isReachable: Bool {
        
        guard isReachableFlagSet else { return false }
        
        if isConnectionRequiredAndTransientFlagSet {
            return false
        }
        
        if isRunningOnDevice {
            if isOnWWANFlagSet && !reachableOnWWAN {
                // We don't want to connect when on 3G.
                return false
            }
        }
        
        return true
    }
    
    var isReachableViaWWAN: Bool {
        // Check we're not on the simulator, we're REACHABLE and check we're on WWAN
        return isRunningOnDevice && isReachableFlagSet && isOnWWANFlagSet
    }
    
    var isReachableViaWiFi: Bool {
        
        // Check we're reachable
        guard isReachableFlagSet else { return false }
        
        // If reachable we're reachable, but not on an iOS device (i.e. simulator), we must be on WiFi
        guard isRunningOnDevice else { return true }
        
        // Check we're NOT on WWAN
        return !isOnWWANFlagSet
    }
    
    var description: String {
        
        let W = isRunningOnDevice ? (isOnWWANFlagSet ? "W" : "-") : "X"
        let R = isReachableFlagSet ? "R" : "-"
        let c = isConnectionRequiredFlagSet ? "c" : "-"
        let t = isTransientConnectionFlagSet ? "t" : "-"
        let i = isInterventionRequiredFlagSet ? "i" : "-"
        let C = isConnectionOnTrafficFlagSet ? "C" : "-"
        let D = isConnectionOnDemandFlagSet ? "D" : "-"
        let l = isLocalAddressFlagSet ? "l" : "-"
        let d = isDirectFlagSet ? "d" : "-"
        
        return "\(W)\(R) \(c)\(t)\(i)\(C)\(D)\(l)\(d)"
    }
}

fileprivate extension Reachability {
    
    func reachabilityChanged() {
        
        let flags = reachabilityFlags
        
        guard previousFlags != flags else { return }
        
        let block = isReachable ? whenReachable : whenUnreachable
        block?(self)
        
        self.notificationCenter.post(name: ReachabilityChangedNotification, object:self)
        
        previousFlags = flags
    }
    
    var isOnWWANFlagSet: Bool {
        #if os(iOS)
        return reachabilityFlags.contains(.isWWAN)
        #else
        return false
        #endif
    }
    var isReachableFlagSet: Bool {
        return reachabilityFlags.contains(.reachable)
    }
    var isConnectionRequiredFlagSet: Bool {
        return reachabilityFlags.contains(.connectionRequired)
    }
    var isInterventionRequiredFlagSet: Bool {
        return reachabilityFlags.contains(.interventionRequired)
    }
    var isConnectionOnTrafficFlagSet: Bool {
        return reachabilityFlags.contains(.connectionOnTraffic)
    }
    var isConnectionOnDemandFlagSet: Bool {
        return reachabilityFlags.contains(.connectionOnDemand)
    }
    var isConnectionOnTrafficOrDemandFlagSet: Bool {
        return !reachabilityFlags.intersection([.connectionOnTraffic, .connectionOnDemand]).isEmpty
    }
    var isTransientConnectionFlagSet: Bool {
        return reachabilityFlags.contains(.transientConnection)
    }
    var isLocalAddressFlagSet: Bool {
        return reachabilityFlags.contains(.isLocalAddress)
    }
    var isDirectFlagSet: Bool {
        return reachabilityFlags.contains(.isDirect)
    }
    var isConnectionRequiredAndTransientFlagSet: Bool {
        return reachabilityFlags.intersection([.connectionRequired, .transientConnection]) == [.connectionRequired, .transientConnection]
    }
    
    var reachabilityFlags: SCNetworkReachabilityFlags {
        
        guard let reachabilityRef = reachabilityRef else { return SCNetworkReachabilityFlags() }
        
        var flags = SCNetworkReachabilityFlags()
        let gotFlags = withUnsafeMutablePointer(to: &flags) {
            SCNetworkReachabilityGetFlags(reachabilityRef, UnsafeMutablePointer($0))
        }
        
        if gotFlags {
            return flags
        } else {
            return SCNetworkReachabilityFlags()
        }
    }
}


