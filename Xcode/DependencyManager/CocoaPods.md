# CocoaPods

- **CocoaPods Install**

  ```Bash
  $ sudo gem install cocoapods
  ```

  

- **Edit Podfile**

  ```shell
  $ pod init
  $ vi Podfile
  ```

  ```
  # Uncomment the next line to define a global platform for your project
  # platform :ios, '9.0'
  
  target 'CocoaPodsSnapKit' do
    # Comment the next line if you don't want to use dynamic frameworks
    use_frameworks!
  
    # Pods for CocoaPodsSnapKit
  	pod '[Library name]'
  end
  ```

  

- **Install Library**

  ```Shell
  $ pod repo update
  $ pod install
  $ open [ProjectName].xcworkspace
  ```

  