//
//  ViewController.swift
//  Recipes
//
//  Created by Andrei Mirzac on 13/06/2018.
//  Copyright © 2018 Andrei Mirzac. All rights reserved.
//

import UIKit

class RecipesViewController: UIViewController {

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var difficultyButton: UIButton!
    @IBOutlet var timeButton: UIButton!
    let refreshControl = UIRefreshControl()

    let sectionInsets = UIEdgeInsets(top: 20.0, left: 5.0, bottom: 20.0, right: 5.0)
    let columns: CGFloat = 2
    let spaceBetweenRows: CGFloat = 20
    let spaceBetweenColumns: CGFloat = 0
    let interitemSpacing: CGFloat = 10

    enum FilterButton: Int {
        case difficulty = 1
        case time
    }

    lazy var viewModel: RecipesViewModel =  {
        let url = "https://mobile.asosservices.com/sampleapifortest/recipes.json"
        let resource = Resource<[Recipe]>(url: url)
        return RecipesViewModel(networkService: NetworkService(), resource: resource)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        registerCells()
        setUpRefreshControl()
        bindToViewModel()
        styleFilterButtons()
        navigationItem.title = viewModel.navigationBarTitle
        viewModel.loadRecipes()
    }

    func bindToViewModel() {
        viewModel.shouldUpdateContent = { [weak self] error in
            self?.collectionView.reloadData()
            self?.refreshControl.endRefreshing()

            if let error = error  {
                self?.showAlert(title: "Network Error", message: error.localizedDescription)
            }
        }

        viewModel.didSelectTimeFilter = { [weak self] time in
            self?.timeButton.setTitle("Time: \(time?.rawValue ?? "All")", for: .normal)
        }

        viewModel.didSelectDifficultyFilter = { [weak self] difficulty in
            self?.difficultyButton.setTitle("Difficulty: \(difficulty?.rawValue ?? "All")", for: .normal)
        }
    }

    func registerCells() {
        let nib = UINib(nibName: RecipeListViewCell.reuseIdentifier , bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: RecipeListViewCell.reuseIdentifier)
    }

    func setUpRefreshControl() {
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }

    @objc func pullToRefresh(refreshControl: UIRefreshControl) {
        viewModel.loadRecipes(isRefresh: true)
    }

    func showAlert(title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }

    func styleFilterButtons() {
        difficultyButton.layer.cornerRadius = 15
        timeButton.layer.cornerRadius = 15
    }
}
//MARK: -
extension RecipesViewController {

    @IBAction func filterBy(sender: UIButton) {
        guard let buttonType = FilterButton(rawValue: sender.tag) else {
            return
        }

        var actionTitles = [String]()
        switch buttonType {
        case .difficulty:
            actionTitles = viewModel.difficultyTitles
        case .time:
            actionTitles = viewModel.timeTitles
        }

        let actionClosure: (UIAlertAction) -> () = { action in
            guard let title = action.title else {
                return
            }

            switch buttonType {
            case .difficulty:
                self.viewModel.filterByDifficulty(rawValue: title)
            case .time:
                self.viewModel.filterByTime(rawValue: title)
            }
        }

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancel)

        for title in actionTitles {
            let action = UIAlertAction(title: title, style: .default, handler: actionClosure)
            actionSheet.addAction(action)
        }
        present(actionSheet, animated: true)
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension RecipesViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //Width
        let screenWidth = UIScreen.main.bounds.width
        let paddingSpace = sectionInsets.left * (columns)
        let availableWidth = screenWidth - paddingSpace - interitemSpacing
        let width = availableWidth / columns

        // Height
        let height = width + (width * 0.50)

        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return spaceBetweenColumns
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return spaceBetweenRows
    }

}

//MARK: - UICollectionViewDataSource UICollectionViewDelegate
extension RecipesViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.recipes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecipeListViewCell.reuseIdentifier, for: indexPath) as? RecipeListViewCell else {
            fatalError("Failed to deque cell of type \(String(describing: RecipeListViewCell.self))")
        }
        cell.setUp(recipe: viewModel.recipes[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let recipe = viewModel.recipes[indexPath.row]
        let recipeDetailViewModel = RecipeDetailViewModel(recipe: recipe)
        let viewController = RecipeDetailViewController(viewModel: recipeDetailViewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

