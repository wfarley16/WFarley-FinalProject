//
//  ImportVC.swift
//  RecipeBook
//
//  Created by William Farley on 4/23/17.
//  Copyright © 2017 William Farley. All rights reserved.
//

import UIKit

class ImportVC: UIViewController {
    
    var recipeToImport = Recipes()
    var page = 1
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var ingredientsField: UITextField!
    @IBOutlet weak var tableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recipeToImport = Recipes()
        
        tableview.delegate = self
        tableview.dataSource = self
        
        tableview.isHidden = true
        
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func searchPressed(_ sender: UIButton) {
        
        page = 1
        
        var formattedKeyword = nameField.text!
        
        if formattedKeyword.contains(" ") {
            formattedKeyword = formattedKeyword.replacingOccurrences(of: " ", with: "+")
        }
        
        var formattedIngredients = ingredientsField.text!
        
        if formattedIngredients.contains(" ") {
            var ingredientsSeachArray = formattedIngredients.components(separatedBy: " ")
            formattedIngredients = ""
            for i in 0...ingredientsSeachArray.count-1 {
                if i != ingredientsSeachArray.count-1 {
                    if ingredientsSeachArray[i].contains(",") {
                        print("Great. They used commas")
                    } else {
                        ingredientsSeachArray[i] = ingredientsSeachArray[i] + ","
                    }
                }
                formattedIngredients += ingredientsSeachArray[i]
            }
            
        }
        
        recipeToImport.getRecipe(ingredients: formattedIngredients, type: formattedKeyword, page: page) {
            if self.recipeToImport.searchArray.count == 0 {
                self.showAlert(title: "Sorry we didn't get any results for that search", message: "Try again with a different keyword or ingredient. Also check your spelling and make sure you aren't using any nonacceptable characters.")
            } else {
                self.tableview.isHidden = false
                self.tableview.reloadData()
            }
        }
        
    }
    
    @IBAction func nextPagePressed(_ sender: UIBarButtonItem) {
        page += 1
        recipeToImport.getRecipe(ingredients: ingredientsField.text!, type: nameField.text!, page: page) {
            self.tableview.reloadData()
        }
    }
    
    @IBAction func backPagePressed(_ sender: UIBarButtonItem) {
        if page > 1 {
            page -= 1
            recipeToImport.getRecipe(ingredients: ingredientsField.text!, type: nameField.text!, page: page) {
                self.tableview.reloadData()
            }
        }
    }
    
}

extension ImportVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipeToImport.searchArray.count-1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ImportRecipeCell
        
        cell.configureImportRecipeCell(title: recipeToImport.searchArray[indexPath.row].title, ingredients: recipeToImport.searchArray[indexPath.row].ingredients, imageURL: recipeToImport.searchArray[indexPath.row].thumbnail)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        recipeToImport.title = recipeToImport.searchArray[indexPath.row].title
        recipeToImport.ingredients = recipeToImport.searchArray[indexPath.row].ingredients
        
        if recipeToImport.searchArray[indexPath.row].thumbnail.characters.count > 0 {
            recipeToImport.imageURL = recipeToImport.searchArray[indexPath.row].thumbnail
        } else {
            recipeToImport.imageURL = "defaultImage"
        }
        
        if recipeToImport.searchArray[indexPath.row].href.characters.count > 0 {
            recipeToImport.href = recipeToImport.searchArray[indexPath.row].href
        } else {
            recipeToImport.href = "Not Available"
        }
        
    }
    
}
