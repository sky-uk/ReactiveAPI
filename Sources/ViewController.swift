import UIKit
import RxSwift

class ViewController: UIViewController {

    var services: Services!
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 5

        stackView.addArrangedSubviews([
            createButton(label: "Login", action: #selector(loginAction)),
            createButton(label: "Invalidate", action: #selector(invalidateAction)),
            createButton(label: "Renew Token", action: #selector(renewTokenAction)),
            createButton(label: "Get Version", action: #selector(getVersionAction)),
            createButton(label: "FlatMap Get Version", action: #selector(flatMapGetVersionAction)),
            createButton(label: "Zip Get Version", action: #selector(zipGetVersionAction))
            ])

        self.view.addSubview(stackView)

        stackView.center(with: view)
    }

    private func createButton(label: String, action: Selector) -> UIButton {
        let button = UIButton()
        button.backgroundColor = .blue
        button.setTitle(label, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)

        return button
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        present(alert, animated: true)
    }

    @objc func loginAction(sender: UIButton!) {
        services.authClient.login(username: "user", password: "password")
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] tokenPair in
                self?.showMessage(title: "Login ok", message: "\(tokenPair)")
                }, onError: { [weak self] error in
                    self?.showMessage(title: "Login error", message: "\(error)")
            }).disposed(by: disposeBag)
    }

    @objc func invalidateAction(sender: UIButton!) {
        services.authClient.invalidate()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in
                self?.showMessage(title: "Invalidate ok", message: "successfully invalidated token")
                }, onError: { [weak self] error in
                    self?.showMessage(title: "Invalidate error", message: "\(error)")
            }).disposed(by: disposeBag)
    }

    @objc func renewTokenAction(sender: UIButton!) {
        services.authClient.renewToken()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] tokenPair in
                self?.showMessage(title: "Token Renew ok", message: "\(tokenPair)")
                }, onError: { [weak self] error in
                    self?.showMessage(title: "Token Renew error", message: "\(error)")
            }).disposed(by: disposeBag)
    }

    @objc func getVersionAction(sender: UIButton!) {
        services.backendAPI.getVersion()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] version in
                self?.showMessage(title: "Version ok", message: "\(version)")
                }, onError: { [weak self] error in
                    self?.showMessage(title: "Version error", message: "\(error)")
            }).disposed(by: disposeBag)
    }

    @objc func flatMapGetVersionAction(sender: UIButton!) {
        services.backendAPI.getVersion()
            .flatMap { _ in
                return self.services.backendAPI.getVersion()
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] version in
                self?.showMessage(title: "Version ok", message: "\(version)")
                }, onError: { [weak self] error in
                    self?.showMessage(title: "Version error", message: "\(error)")
            }).disposed(by: disposeBag)
    }

    @objc func zipGetVersionAction(sender: UIButton!) {
        Single.zip(services.backendAPI.getVersion(), services.backendAPI.getVersion())
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] _, version in
                self?.showMessage(title: "Version ok", message: "\(version)")
                }, onError: { [weak self] error in
                    self?.showMessage(title: "Version error", message: "\(error)")
            }).disposed(by: disposeBag)
    }

}
