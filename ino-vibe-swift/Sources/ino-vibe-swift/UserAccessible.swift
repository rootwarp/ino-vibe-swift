//
//  File.swift
//  
//
//  Created by Mindhack on 12/15/20.
//

import Foundation


public protocol UserAccessible {
    func profile()
}

public class UserManagerFactory {

    public static func getManager() -> UserAccessible {
        return UserManager()
    }

}

class UserManager: UserAccessible {

    func profile() {

    }

}
