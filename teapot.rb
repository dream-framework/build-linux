
#
#  This file is part of the "Teapot" project, and is released under the MIT license.
#

teapot_version "3.0"

define_target "build-linux" do |target|
	target.depends :platform, public: true
	
	target.provides :linker => "Build/linux"
	target.provides :executor => "Build/linux"
	
	target.provides "Build/linux" do
		define Rule, "link.linux-static-library" do
			input :object_files, pattern: /\.o/, multiple: true
			
			output :library_file, pattern: /\.a/
			
			apply do |parameters|
				input_root = parameters[:library_file].root
				object_files = parameters[:object_files].collect{|path| path.shortest_path(input_root)}
				
				rm parameters[:library_file]
				
				run!(
					environment[:ar] || "ar", 
					environment[:arflags] || "-cr",
					parameters[:library_file].relative_path,
					*object_files,
					chdir: input_root
				)
			end
		end
		
		define Rule, "link.linux-executable" do
			input :object_files, pattern: /\.o$/, multiple: true
			
			input :dependencies, implicit: true do |arguments|
				libraries = environment[:ldflags].select{|option| option.kind_of? Files::Path}
			end
			
			output :executable_file
			
			apply do |parameters|
				input_root = parameters[:executable_file].root
				object_files = parameters[:object_files].collect{|path| path.shortest_path(input_root)}
				
				run!(
					"clang++",
					"-o", parameters[:executable_file].relative_path,
					*object_files,
					*environment[:ldflags],
					chdir: input_root
				)
			end
		end
		
		define Rule, "build.static-library" do
			input :source_files
			
			parameter :prefix, implicit: true do |arguments|
				arguments[:prefix] = environment[:build_prefix] + environment.checksum
			end
			
			parameter :static_library
			
			output :library_file, implicit: true do |arguments|
				arguments[:prefix] / "#{arguments[:static_library]}.a"
			end
			
			apply do |parameters|
				# Make sure the output directory exists:
				mkpath File.dirname(parameters[:library_file])
				
				build build_prefix: parameters[:prefix], source_files: parameters[:source_files], library_file: parameters[:library_file]
			end
		end
		
		define Rule, "build.executable" do
			input :source_files
			
			parameter :prefix, implicit: true do |arguments|
				arguments[:prefix] = environment[:build_prefix] + environment.checksum
			end
			
			parameter :executable
			
			output :executable_file, implicit: true do |arguments|
				arguments[:prefix] / arguments[:executable]
			end
			
			apply do |parameters|
				# Make sure the output directory exists:
				mkpath File.dirname(parameters[:executable_file])
				
				build build_prefix: parameters[:prefix], source_files: parameters[:source_files], executable_file: parameters[:executable_file]
			end
		end
		
		define Rule, "run.executable" do
			parameter :executable_file
						
			parameter :prefix, implicit: true do |arguments|
				arguments[:prefix] ||= File.dirname(arguments[:executable_file])
			end
			
			parameter :arguments, optional: true
			
			apply do |parameters|
				run!(
					parameters[:executable_file],
					*parameters[:arguments],
					chdir: parameters[:prefix]
				)
			end
		end
	end
end
