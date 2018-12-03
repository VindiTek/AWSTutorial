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

class NotesTableViewController: UITableViewController {
    
    // MARK: - Static init
    static func instantiate() -> NotesTableViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil) as UIStoryboard?
        let vc = storyboard?.instantiateViewController(withIdentifier: String(describing: self)) as! NotesTableViewController
        return vc
    }
    
    // MARK: - Private properties
    private let dynamoDBService: DynamoDBServiceProtocol = DynamoDBService()
    private var notes: [Note] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        placeAddButton()
        navigationItem.title = "Notes"
        configureRefreshControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNotes()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "noteCell", for: indexPath)
        cell.textLabel?.text = notes[indexPath.row]._title ?? ""
        return cell
    }
    
    // MARK: - Private
    private func placeAddButton() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonAction))
        navigationItem.rightBarButtonItem = addButton
    }
    
    private func configureRefreshControl() {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(loadNotes), for: .valueChanged)
        refreshControl = refresh
    }
    
    //MARK: - Load Notes
    @objc private func loadNotes() {
        refreshControl?.beginRefreshing()
        dynamoDBService.loadNotes { [weak self] (notes, error) in
            guard let strongSelf = self else {return}
            strongSelf.refreshControl?.endRefreshing()
            strongSelf.notes = notes
            strongSelf.tableView.reloadSections([0], with: .automatic)
        }
    }
    
    // MARK: - Actions
    @objc private func addButtonAction() {
        let vc = NoteViewController.instantiate(with: .add)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let noteId = notes[indexPath.row]._noteId else { return }
        dynamoDBService.getNote(by: noteId) { [weak self] (note, error) in
            guard let newNote = note else { return }
            guard let strongSelf = self else { return }
            let vc = NoteViewController.instantiate(with: .edit(newNote))
            strongSelf.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { [weak self] (rowAction: UITableViewRowAction, indexPath: IndexPath) -> Void in
            guard let strongSelf = self else { return }
            strongSelf.dynamoDBService.delete(note: strongSelf.notes[indexPath.row], completion: { [weak self, indexPath] error in
                guard let strongSelf = self else { return }
                if let error = error {
                    print("Delete Faield: \(error.localizedDescription)")
                    return
                }
                strongSelf.notes.remove(at: indexPath.row)
                strongSelf.tableView.deleteRows(at: [indexPath], with: .automatic)
            })
        }
        return [deleteAction]
    }
    
}
