//
// PermissionAlert.swift
//
// Copyright (c) 2015-2016 Damien (http://delba.io)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

open class PermissionAlert {
    /// The permission.
    fileprivate let permission: Permission
    
    /// The status of the permission.
    fileprivate var status: PermissionStatus { return permission.status }
    
    /// The domain of the permission.
    fileprivate var type: PermissionType { return permission.type }
    
    fileprivate var callbacks: Permission.Callback { return permission.callbacks }
    
    /// The title of the alert.
    open var title: String?
    
    /// Descriptive text that provides more details about the reason for the alert.
    open var message: String?
    
    /// The title of the cancel action.
    open var cancel: String? {
        get { return cancelActionTitle }
        set { cancelActionTitle = newValue }
    }
    
    /// The title of the settings action.
    open var settings: String? {
        get { return defaultActionTitle }
        set { defaultActionTitle = newValue }
    }
    
    /// The title of the confirm action.
    open var confirm: String? {
        get { return defaultActionTitle }
        set { defaultActionTitle = newValue }
    }
    
    fileprivate var cancelActionTitle: String?
    fileprivate var defaultActionTitle: String?
    
    var controller: UIAlertController {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: cancelActionTitle, style: .cancel, handler: cancelHandler)
        controller.addAction(action)
        
        return controller
    }
    
    internal init(permission: Permission) {
        self.permission = permission
    }
    
    internal func present() {
        DispatchQueue.main.async {
            UIApplication.shared.presentViewController(self.controller)
        }
    }

    fileprivate func cancelHandler(_ action: UIAlertAction) {
        callbacks(status)
    }
}

internal class DisabledAlert: PermissionAlert {
    override init(permission: Permission) {
        super.init(permission: permission)
        
        switch permission.type {
            
        case .contacts:
            title   = "\(Bundle.main.name) n'a pas accès à vos contacts"
            message = "L’application requiert l'accès aux contacts de votre iPhone pour pouvoir vous connecter à la communauté Widr. Pour autoriser l'accès appuyez sur Réglages et activez les contacts."
            cancel  = NSLocalizedString("OK", comment: "")
            
        case .notifications:
            title   = "\(Bundle.main.name) n'a pas accès à vos notifications"
            message = "L’application requiert l'accès aux notifications pour vous informer des recommandations et actualités vous concernant. Pour autoriser l'accès appuyez sur Réglages et activez notifications."
            cancel  = NSLocalizedString("OK", comment: "")
            
        default:
            title   = "\(Bundle.main.name) n'a pas accès à \(permission)"
            message = "L’application requiert ce service pour une utilisation optimale. Pour autoriser l’accès, appuyez sur paramètres et activez ce dernier."
            cancel  = NSLocalizedString("OK", comment: "")
            
        }
        
    }
}

internal class DeniedAlert: PermissionAlert {
    override var controller: UIAlertController {
        let controller = super.controller
        
        let action = UIAlertAction(title: defaultActionTitle, style: .default, handler: settingsHandler)
        controller.addAction(action)

        if #available(iOS 9.0, *) {
            controller.preferredAction = action
        }
        
        return controller
    }
    
    override init(permission: Permission) {
        super.init(permission: permission)
        
        switch permission.type {
            
        case .contacts:
            title   = NSLocalizedString(String(format: "%@ does not have access to contacts", Bundle.main.name), comment: "")
            message = NSLocalizedString("Widr would like to access your Contacts in order to connect with other members while protecting your identity. Please enable access to Contacts in the Settings app.", comment: "")
            cancel   = NSLocalizedString("Cancel", comment: "")
            settings = NSLocalizedString("Settings", comment: "")
            
        case .notifications:
            title   = NSLocalizedString(String(format: "%@ does not have access to notifications", Bundle.main.name), comment: "")
            message = NSLocalizedString("The application requires access to notifications to inform you of recommendations and news which concern you. Please turn on notifications in the Settings app.", comment: "")
            cancel   = NSLocalizedString("Cancel", comment: "")
            settings = NSLocalizedString("Settings", comment: "")
            
        default:
            
            title    = NSLocalizedString(String(format: "Permission for %@ was denied", permission), comment: "")
            message  = NSLocalizedString(String(format: "Please enable access to %@ in the Settings app.", permission), comment: "")
            cancel   = NSLocalizedString("Cancel", comment: "")
            settings = NSLocalizedString("Settings", comment: "")
            
        }
        
        
    }
    
    @objc func settingsHandler() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification)
        callbacks(status)
    }
    
    private func settingsHandler(_ action: UIAlertAction) {
        NotificationCenter.default.addObserver(self, selector: .settingsHandler, name: UIApplication.didBecomeActiveNotification)
        
        if let URL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.openURL(URL)
        }
    }
}

internal class PrePermissionAlert: PermissionAlert {
    override var controller: UIAlertController {
        let controller = super.controller
        
        let action = UIAlertAction(title: defaultActionTitle, style: .default, handler: confirmHandler)
        controller.addAction(action)

        if #available(iOS 9.0, *) {
            controller.preferredAction = action
        }
        
        return controller
    }
    
    override init(permission: Permission) {
        super.init(permission: permission)
        
        title   = NSLocalizedString(String(format: "%@ would like to access your %@", Bundle.main.name, permission), comment: "")
        message = nil
        cancel  = NSLocalizedString("Cancel", comment: "")
        confirm = NSLocalizedString("Confirm", comment: "")
    }
    
    fileprivate func confirmHandler(_ action: UIAlertAction) {
        permission.requestAuthorization(callbacks)
    }
}
