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

import UIKit

enum NoteControllerState {
    case add, edit(Note)
    
    var navigationTitle: String {
        switch self {
        case .add:          return "Creation"
        case .edit(_):      return "Editing"
        }
    }
}

class NoteViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    //MARK: - Outlets
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentTextView: UITextView!
    
    //MARK: - Private properties
    private var state: NoteControllerState = .add
    private let dynamoDBService: DynamoDBServiceProtocol = DynamoDBService()
    
    //MARK: - Static init
    static func instantiate(with state: NoteControllerState) -> NoteViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil) as UIStoryboard?
        let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: self)) as! NoteViewController
        vc.state = state
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSaveButton()
        navigationItem.title = state.navigationTitle
        configureUI(withState: state)
    }
    
    //MARK: - Private
    private func configureUI(withState state: NoteControllerState) {
        if case .edit(let note) = state {
            titleTextField.text = note._title ?? ""
            contentTextView.text = note._content ?? ""
        }
    }
    
    private func addSaveButton() {
        let barButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonAction))
        navigationItem.rightBarButtonItem = barButton
    }
    
    @objc private func saveButtonAction() {
        view.endEditing(true)
        guard let note = createNote() else {return}
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        dynamoDBService.updateNote(note) { [weak self] (note, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if error != nil {
                // Here should be alert with error
                print(error?.localizedDescription ?? "Something went wrong")
            } else {
                guard let strongSelf = self else {return}
                strongSelf.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func createNote() -> Note? {
        guard case .edit(let note) = state else {
            let newNote = Note()
            newNote?._title = titleTextField.text
            newNote?._content = contentTextView.text
            return newNote
        }
        
        note._title = titleTextField.text
        note._content = contentTextView.text
        return note
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        contentTextView.becomeFirstResponder()
        return true
    }
    
    // MARK: - UITextViewDelegate
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
        }
        return true
    }

}
