//
//  Notes.swift
//  MySampleApp
//
//
// Copyright 2018 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.21
//

import Foundation
import UIKit
import AWSDynamoDB

@objcMembers
class Note: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var _userId: String?
    var _noteId: String?
    var _content: String?
    var _creationDate: NSNumber?
    var _title: String?
    
    class func dynamoDBTableName() -> String {
        
        return "YOUR-TABLE-NAME"
    }
    
    class func hashKeyAttribute() -> String {
        
        return "_userId"
    }
    
    class func rangeKeyAttribute() -> String {
        
        return "_noteId"
    }
    
    override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
        return [
            "_userId" : "userId",
            "_noteId" : "noteId",
            "_content" : "content",
            "_creationDate" : "creationDate",
            "_title" : "title",
        ]
    }
}
