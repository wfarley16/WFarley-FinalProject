//
//  DetailVC.swift
//  RecipeBook
//
//  Created by William Farley on 4/22/17.
//  Copyright © 2017 William Farley. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class DetailVC: UIViewController {
    
    var pickerIndex = 0
    var lastIndex = 0
    var recipesArray = [Recipes]()
    var ingredientsArray = [String]()
    
    var recipesRef: FIRDatabaseReference!
    var ingredientsRef: FIRDatabaseReference!
    
    var userDisplayName = ""
    
    @IBOutlet weak var recipeImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ingredientsLabel: UILabel!
    @IBOutlet weak var linkButton: UIButton!
    @IBOutlet weak var recipePicker: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if titleLabel.text == "Not A Recipe" {
            titleLabel.isHidden = true
            ingredientsLabel.isHidden = true
            linkButton.isHidden = true
            recipePicker.isHidden = true
        }
        
        recipePicker.delegate = self
        recipePicker.dataSource = self
        
        recipesRef = FIRDatabase.database().reference(withPath: "recipes")
        
        recipesRef.observe(.value, with: { snapshot in
            self.recipesArray = []
            for child in snapshot.children {
                let recipeSnapshot = child as! FIRDataSnapshot
                let newRecipe = Recipes()
                let recipeValue = recipeSnapshot.value as! [String: AnyObject]
                newRecipe.title = recipeValue["title"] as! String
                newRecipe.ingredients = recipeValue["ingredients"] as! String
                newRecipe.imageURL = recipeValue["imageURL"] as! String
                newRecipe.href = recipeValue["href"] as! String
                newRecipe.recipeKey = recipeSnapshot.key
                self.recipesArray.append(newRecipe)
            }
            
            if self.recipesArray.count == 0 {
                self.performSegue(withIdentifier: "ToListVC", sender: nil)
            } else {
                self.refreshUI()
            }
            
            self.ingredientsRef = FIRDatabase.database().reference(withPath: "ingredients")
            
            self.ingredientsRef.observe(.value, with: { snapshot in
                self.ingredientsArray = []
                for child in snapshot.children {
                    let ingredientSnapshot = child as! FIRDataSnapshot
                    let ingredientValue = ingredientSnapshot.value as! [String: AnyObject]
                    let newIngredient = ingredientValue["ingredient"] as! String
                    self.ingredientsArray.append(newIngredient)
                }
                
            self.conditionalFormat()

            })
        })
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            print("User has signed in")
            let displayName = FIRAuth.auth()?.currentUser?.displayName
        } else {
            performSegue(withIdentifier: "ToSignIn", sender: nil)
        }
    }
    
    func conditionalFormat() {
        if self.ingredientsArray.count > 0 {
            var index = 0
            let ingredientsInRecipe = self.recipesArray[self.pickerIndex].ingredients.components(separatedBy: ", ")
            
            for i in 0...ingredientsInRecipe.count-1 {
                if self.ingredientsArray.contains(ingredientsInRecipe[i]) {
                    index += 1
                }
            }
            
            if index == ingredientsInRecipe.count {
                self.titleLabel.textColor = UIColor.black
            } else {
                self.titleLabel.textColor = UIColor.red
            }
        }
    }
    
    func refreshUI() {
        
        if recipesArray[pickerIndex].imageURL.contains("http://") {
            let imageURL = URL(string: recipesArray[pickerIndex].imageURL)
            let data = try? Data(contentsOf: imageURL!)
            recipeImage.image = UIImage(data: data!)
        } else {
            if recipesArray[pickerIndex].imageURL == "defaultImage" {
                recipeImage.image = UIImage(named: recipesArray[pickerIndex].imageURL)
            } else {
                print("Here is where you'd fetch an image from your directory that was stored locally.")
            }
        }
        
        recipeImage.isHidden = false
        titleLabel.isHidden = false
        ingredientsLabel.isHidden = false
        
        titleLabel.text = recipesArray[pickerIndex].title
        ingredientsLabel.text = recipesArray[pickerIndex].ingredients
        
        if recipesArray[pickerIndex].href == "Not Available" {
            linkButton.isHidden = true
        } else {
            linkButton.isHidden = false
            linkButton.setTitle(recipesArray[pickerIndex].href, for: .normal)
        }
        
        recipePicker.isHidden = false
        
        recipePicker.reloadAllComponents()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ToListVC" {
            let destVC = segue.destination as! UINavigationController
            let targetVC = destVC.topViewController as! ListVC
            targetVC.recipesArray = recipesArray
        }
        
    }
    
    @IBAction func unwindToDetailVC(sender: UIStoryboardSegue) {
        
        if let userDisplayName = FIRAuth.auth()?.currentUser?.displayName {
            self.userDisplayName = userDisplayName
        } else {
            self.userDisplayName = "Unknown"
        }
        
        if let sourceVC = sender.source as? ListVC {
            recipesArray = sourceVC.recipesArray
        }
        
        if let sourceVC = sender.source as? FridgeVC {
            for i in 0...sourceVC.ingredientsArray.count-1 {
                ingredientsArray.append(sourceVC.ingredientsArray[i].ingredient)
            }
        }
        
        refreshUI()
    }
    
    @IBAction func linkButtonPressed(_ sender: UIButton) {
        UIApplication.shared.openURL(URL(string: recipesArray[pickerIndex].href)!)
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        GIDSignIn.sharedInstance().signOut()
        performSegue(withIdentifier: "ToSignIn", sender: nil)
    }
    
    @IBAction func infoPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Welcome to Your Recipe Book", message: "Couple Things: if a recipe title appears as red then you don't have all the listed ingredients, you can manage your list of ingredients by pressing What's in My Fridge below. Also, please sign in through Google as that is how we store your recipe book data, and it will allow you to share your recipes with others.", preferredStyle: .alert)
        let alertAction = UIAlertAction.init(title: "Ok", style: .default, handler: nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension DetailVC: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return recipesArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return recipesArray[row].title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerIndex = row
        self.conditionalFormat()
        refreshUI()
    }
}






