// MIT License

// Copyright (c) 2018 VindiTek

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import AWSDynamoDB
import AWSAuthCore

typealias GetNoteResponse = (_ note: Note?, _ error: Error?) -> ()
typealias UpdateNoteResponse = (_ note: Note, _ error: Error?) -> ()
typealias LoadNotesResponse = (_ notes: [Note], _ error: Error?) -> ()
typealias DeleteNoteResponse = (_ error: Error?) -> ()


protocol DynamoDBServiceProtocol {
    func getNote(by id: String, completion: @escaping GetNoteResponse)
    func loadNotes(completion: @escaping LoadNotesResponse)
    func updateNote(_ note: Note, completion: @escaping UpdateNoteResponse)
    func delete(note: Note, completion: @escaping DeleteNoteResponse)
}

final class DynamoDBService: DynamoDBServiceProtocol {
    
    //MARK: - Private properties
    /// Will be used to work with the data in DynamoDB
    private let awsMapper = AWSDynamoDBObjectMapper.default()
    /// Will be used to work only with Notes created by our user and only owner of notes can work with them (create/update/read/delete) as they are private
    private let userIdentityId = AWSIdentityManager.default().identityId ?? ""
    
    //MARK: - DynamoDBServiceProtocol
    func getNote(by id: String, completion: @escaping GetNoteResponse) {
        fetchNote(by: id, completion: completion)
    }
    
    func loadNotes(completion: @escaping LoadNotesResponse) {
        load(completion: completion)
    }
    
    func updateNote(_ note: Note, completion: @escaping UpdateNoteResponse) {
        update(with: note, completion: completion)
    }
    
    func delete(note: Note, completion: @escaping DeleteNoteResponse) {
        remove(note: note, completion: completion)
    }
    
    //MARK: - Implementation
    private func fetchNote(by id: String, completion: @escaping GetNoteResponse) {
        awsMapper.load(Note.self, hashKey: userIdentityId, rangeKey: id).continueWith(executor: AWSExecutor.mainThread()) { task -> Any? in
            if let error = task.error {
                completion(nil, error)
                print("Amazon DynamoDB Read Error: \(error)")
                return nil
            }
            guard let note = task.result as? Note else {
                completion(nil, task.error)
                return nil
            }
            print("An item was read.")
            completion(note, nil)
            return nil
        }
    }
    private func load(completion: @escaping LoadNotesResponse) {
        
        /// We are creating this expression to say that we are only interested in our own Notes.
        /// Anyway if we will try to load someone's Notes, Amazon will return Auth error to us as we have selected private table.
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.expressionAttributeNames = ["#userId": "userId"]
        queryExpression.keyConditionExpression = "#userId = :userId"
        queryExpression.expressionAttributeValues = [
            ":userId" : userIdentityId
        ]
        
        awsMapper.query(Note.self, expression: queryExpression).continueWith(executor: AWSExecutor.mainThread()) { task -> Any? in
            if task.error != nil {
                completion([], task.error)
                return nil
            }
            guard let notes = (task.result)?.items as? [Note] else {
                print("Returned objects not Notes")
                completion([], nil)
                return nil
            }
            /// Sorting Notes by creationDate locally at this point.
            let sortedByDateNotes = notes.sorted { $0._creationDate?.doubleValue ?? 0 < $1._creationDate?.doubleValue ?? 0  }
            completion(sortedByDateNotes, nil)
            return nil
        }
    }
    
    private func update(with note: Note, completion: @escaping UpdateNoteResponse) {
        /// Create data object using data models you downloaded from Mobile Hub
        let newNote: Note = Note()
        newNote._userId = userIdentityId
        
        /// If passed Note has no _noteId we are creating new using UUDI().uuidString.
        newNote._noteId = note._noteId ?? UUID().uuidString
        
        /// Filling information
        newNote._title = note._title
        newNote._content = note._content
        newNote._creationDate = note._creationDate ?? Date().timeIntervalSince1970 as NSNumber
        
        //Save an item
        awsMapper.save(newNote).continueWith(executor: AWSExecutor.mainThread()) { [newNote] task -> Any? in
            if let error = task.error {
                print("Amazon DynamoDB Save Error: \(error)")
                completion(newNote, error)
                return nil
            }
            print("An item was saved.")
            completion(newNote, task.error)
            return nil
        }
    }
    
    private func remove(note: Note, completion: @escaping DeleteNoteResponse) {
        awsMapper.remove(note).continueWith(executor: AWSExecutor.mainThread()) { task -> Any? in
            if let error = task.error {
                completion(error)
                return nil
            }
            completion(nil)
            return nil
        }
    }
    
}
