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
import AWSFacebookSignIn
import FBSDKLoginKit

class ViewController: UIViewController {

    // MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // MARK: - Actions
    @IBAction func loginWithFacebookButtonAction(_ sender: UIButton) {
        let provider = AWSFacebookSignInProvider.sharedInstance()
        provider.setViewControllerForFacebookSignIn(self)
        provider.setLoginBehavior(FBSDKLoginBehavior.native.rawValue)
        AWSSignInManager.sharedInstance().login(signInProviderKey: provider.identityProviderName) { [weak self] (result, error) in
            if error == nil {
                print("Signed in with Facebook!")
                guard let strongSelf = self else {return}
                let vc = NotesTableViewController.instantiate()
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            } else {
                let errorText = (error as NSError?)?.userInfo["message"] as? String ?? "Something went wrong"
                print("Facebook sign in failed. See details below.")
                print(errorText)
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
