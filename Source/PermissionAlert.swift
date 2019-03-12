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
            message = "L’application requiert l'accès aux contacts de votre iPhone pour pouvoir vous connecter à la communauté Widr. Pour autoriser l'accès appuyez sur Réglages et activer les contacts."
            cancel  = "ОК"
            
        case .notifications:
            title   = "\(Bundle.main.name) n'a pas accès à vos notifications"
            message = "L’application requiert l'accès aux notifications de votre iPhone pour pouvoir vous informer des demandes de recommandations de vos proches et les dernières actualités vous concernant."
            cancel  = "ОК"
            
        default:
            title   = "\(Bundle.main.name) n'a pas accès à \(permission)"
            message = "L’application requiert ce service pour une utilisation optimale. Pour autoriser l’accès, appuyez sur paramètres et activez ce dernier."
            cancel  = "ОК"
            
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
            title   = "\(Bundle.main.name) n'a pas accès à vos contacts"
            message = "L’application requiert l'accès aux contacts de votre iPhone pour pouvoir vous connecter à la communauté Widr. Pour autoriser l'accès appuyez sur Réglages et activer les contacts."
            cancel   = "Annuler"
            settings = "Réglages"
            
        case .notifications:
            title   = "\(Bundle.main.name) n'a pas accès à vos notifications"
            message = "L’application requiert l'accès aux notifications de votre iPhone pour pouvoir vous informer des demandes de recommandations de vos proches et les dernières actualités vous concernant."
            cancel   = "Annuler"
            settings = "Réglages"
            
        default:
            title    = "\(Bundle.main.name) n'a pas accès à \(permission)"
            message  = "L’application requiert ce service pour une utilisation optimale. Pour autoriser l’accès, appuyez sur paramètres et activez ce dernier."
            cancel   = "Annuler"
            settings = "Réglages"
            
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
        
        title   = "\(Bundle.main.name) souhaite accéder à \(permission)"
        message = nil
        cancel  = "Annuler"
        confirm = "Authoriser"
    }
    
    fileprivate func confirmHandler(_ action: UIAlertAction) {
        permission.requestAuthorization(callbacks)
    }
}
