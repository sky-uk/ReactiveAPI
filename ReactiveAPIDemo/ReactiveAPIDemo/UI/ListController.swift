import UIKit
import RxCocoa
import RxSwift

class ListController: UITableViewController {
    
    let disposeBag = DisposeBag()
    var viewModel: ViewModel!
    var viewModelFactory: ViewModelFactory?
    var data = [ViewModelData]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(SubtitleUITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        viewModel.fetch(controller: self)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
        
        let cellData = data[indexPath.row]
        
        cell.textLabel?.text = cellData.title
        cell.detailTextLabel?.text = cellData.subtitle
        
        if viewModelFactory?.hasViewModel(for: indexPath) ?? false {
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if viewModelFactory?.hasViewModel(for: indexPath) ?? false {
            return indexPath
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel = viewModelFactory?.viewModel(for: indexPath, data: data) else {
            return
        }
        
        let controller = ListController(style: .grouped)
        controller.viewModel = viewModel
        controller.viewModelFactory = viewModelFactory?.childViewModelFactory(for: indexPath, data: data)
        controller.title = data[indexPath.row].title
        
        navigationController?.pushViewController(controller, animated: true)
    }
}



