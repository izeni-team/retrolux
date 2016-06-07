Pod::Spec.new do |spec|
  spec.name = 'Retrolux'
  spec.version = '0.0.5'
  spec.license = { :type => 'MIT' }
  spec.homepage = 'https://dev.izeni.net/bhenderson/retrolux'
  spec.authors = { 'Bryan Henderson' => 'bhenderson@izeni.com' }
  spec.summary = 'All in one REST framework for Swift.'
  spec.source = { :git => 'https://dev.izeni.net/bhenderson/retrolux.git', :tag => 'v#{spec.version}' }
  spec.source_files = 'Retrolux/Serializer.swift', 'Retrolux/Retrolux.swift'
end

