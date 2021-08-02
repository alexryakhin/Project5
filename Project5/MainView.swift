//
//  MainView.swift
//  MainView
//
//  Created by Alexander Bonney on 7/31/21.
//

import UIKit

class MainView: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    
    var usedWords = Array<String>()
    var allWords = Array<String>()
    
    private var rootWord = ""
    private var newWord = ""
    private var score = 0
    
    private let tableView = UITableView()
    private let scoreLabel = UILabel()
    private let textField = UITextField()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New Game", style: .plain, target: self, action: #selector(newGame))
        
        startGame()
        title = rootWord
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        view.addSubview(textField)
        view.addSubview(scoreLabel)
        scoreLabel.text = "Score: \(score)"
        scoreLabel.textAlignment = .center
        textField.borderStyle = .roundedRect
        textField.backgroundColor = UIColor.lightText
        textField.placeholder = "Enter your word"
        textField.delegate = self
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        
        tableView.backgroundColor = .systemBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Word")
        tableView.isScrollEnabled = false
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usedWords.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row + 1). " + usedWords[indexPath.row]
        return cell
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else {
            return true
        }
        //MARK: add new word here
        
        newWord = text
        addNewWord()
        tableView.reloadData()
        textField.text?.removeAll()
        textField.resignFirstResponder()
        
        
        return true
    }
    
    func startGame() {
        // 1. Find the URL for start.txt in our app bundle
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            // we found the file in our bundle! 2. Load start.txt into a string
            if let startWords = try? String(contentsOf: startWordsURL) {
                // 3. Split the string up into an array of strings, splitting on line breaks
                allWords = startWords.components(separatedBy: "\n")
                rootWord = allWords.randomElement() ?? "silkworm"
                return
            }
        }
        
        // If were are *here* then there was a problem – trigger a crash and report the error
        fatalError("Could not load start.txt from bundle.")
    }
    
    @objc func newGame() {
        usedWords.removeAll(keepingCapacity: true)
        rootWord = allWords.randomElement() ?? "silkworm"
        title = rootWord
        score = 0
        scoreLabel.text = "Score: \(score)"
        tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(
            x: 0,
            y: 200,
            width: view.width,
            height: view.height - 250)
        
        textField.frame = CGRect(
            x: 10,
            y: 140,
            width: view.width - 20,
            height: 50)
        
        scoreLabel.frame = CGRect(
            x: 10,
            y: view.height - 60,
            width: view.width - 20,
            height: 50)
    }
    
    func addNewWord() {
        // lowercase and trim the word, to make sure we don't add duplicate words with case differences
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // exit if the remaining string is empty
        guard answer.count > 0 else {
            return
        }
        guard isOriginal(word: answer) else {
            showAlert(title: "Word used already", message: "Be more original. You lose 2 score points.")
            score -= 2
            scoreLabel.text = "Score: \(score)"
            return
        }
        
        guard isPossible(word: answer) else {
            showAlert(title: "Word not recognized", message: "You can't just make them up, you know! You lose 3 score points.")
            score -= 3
            scoreLabel.text = "Score: \(score)"
            return
        }
        
        guard isReal(word: answer) else {
            showAlert(title: "Word not possible", message: "That word is shorter than 3 letters, or it doesn't exist. You lose 5 score points.")
            score -= 5
            scoreLabel.text = "Score: \(score)"
            return
        }
        score += 10
        scoreLabel.text = "Score: \(score)"
        //        print(score)
        usedWords.insert(answer, at: 0)
        newWord = ""
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    func isPossible(word: String) -> Bool {
        //if we create a variable copy of the root word, we can then loop over each letter of the user’s input word to see if that letter exists in our copy. If it does, we remove it from the copy (so it can’t be used twice), then continue. If we make it to the end of the user’s word successfully then the word is good, otherwise there’s a mistake and we return false.
        
        var tempWord = rootWord
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                return false
            }
        }
        return true
    }
    
    func isReal(word: String) -> Bool {
        // The final method is harder, because we need to use UITextChecker from UIKit. In order to bridge Swift strings to Objective-C strings safely, we need to create an instance of NSRange using the UTF-16 count of our Swift string. This isn’t nice, I know, but I’m afraid it’s unavoidable until Apple cleans up these APIs.
        
        //So, our last method will make an instance of UITextChecker, which is responsible for scanning strings for misspelled words. We’ll then create an NSRange to scan the entire length of our string, then call rangeOfMisspelledWord() on our text checker so that it looks for wrong words. When that finishes we’ll get back another NSRange telling us where the misspelled word was found, but if the word was OK the location for that range will be the special value NSNotFound.
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        
        if range.length > 2 && newWord != rootWord {
            let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
            return misspelledRange.location == NSNotFound
        } else {
            return false
        }
        
    }
    
    func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "I got it", style: .default, handler: nil))
        present(ac, animated: true)
    }
    
}
