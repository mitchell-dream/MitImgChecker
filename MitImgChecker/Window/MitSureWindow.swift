//
//  MitSureWindow.swift
//  MITSourceChecker
//
//  Created by MENGCHEN on 2019/8/21.
//  Copyright © 2019 Mitchell. All rights reserved.
//

import Cocoa
class MitSureWindow: NSWindow {
    public var text=""
    @IBOutlet weak var textField: NSTextField!
    typealias makeSureBlock = ()->(Void);
    typealias cancelBlock = ()->(Void);
    var makeSureHandler:makeSureBlock? = nil
    var canelHandler:cancelBlock? = nil
    func sureClickCallback (closure:@escaping() -> Void) {
        makeSureHandler = closure
    }
    func cancelClickCallback (closure:@escaping() -> Void) {
        canelHandler = closure
    }
    @IBAction func sureClick(_ sender: Any) {
        self.close()
        makeSureHandler?()
    }
    
    @IBAction func cancelClick(_ sender: Any) {
        self.close()
        canelHandler?()
    }
}
