
#
#  This file is part of the "Teapot" project, and is released under the MIT license.
#

teapot_version "1.0.0"

define_target "build-linux" do |target|
	target.provides :linker => "Build/linux"
	
	target.provides "Build/linux" do
		define Rule, "link.linux-static-library" do
			input :object_files, pattern: /\.o/, multiple: true
			output :library_file, pattern: /\.a/
			
			apply do |parameters|
				input_root = parameters[:library_file].root
				object_files = parameters[:object_files].collect{|path| path.shortest_path(input_root)}
				
				run!(
					environment[:ar] || "ar", 
					environment[:arflags] || "-cru",
					parameters[:library_file].relative_path,
					*object_files,
					chdir: input_root
				)
			end
		end
		
		define Rule, "link.linux-dynamic-library" do
			input :object_files, pattern: /\.o$/, multiple: true
			output :library_file, pattern: /\.(so)$/
			
			apply do |parameters|
				input_root = parameters[:library_file].root
				object_files = parameters[:object_files].collect{|path| path.shortest_path(input_root)}
				
				run!(
					environment[:libtool] || "libtool",
					"-dynamic",
					"-o", parameters[:library_file].relative_path,
					"-c", *object_files,
					*environment[:ldflags],
					"-L" + (environment[:install_prefix] + "lib").shortest_path(input_root),
					chdir: input_root
				)
			end
		end
		
		define Rule, "link.linux-executable" do
			input :object_files, pattern: /\.o$/, multiple: true
			output :executable_file
			
			apply do |parameters|
				input_root = parameters[:executable_file].root
				object_files = parameters[:object_files].collect{|path| path.shortest_path(input_root)}
				
				run!(
					environment[:cxx],
					"-o", parameters[:executable_file],
					*parameters[:object_files],
					*environment[:ldflags],
					"-L" + (environment[:install_prefix] + "lib").shortest_path(input_root),
					chdir: input_root
				)
			end
		end
		
		define Rule, "build.static-library" do
			input :source_files
			
			parameter :prefix
			parameter :static_library
			
			output :library_file, implicit: true do |arguments|
				arguments[:prefix] + "lib" + "lib#{arguments[:static_library]}.a"
			end
			
			apply do |parameters|
				# Make sure the output directory exists:
				fs.mkpath File.dirname(parameters[:library_file])
				
				build source_files: parameters[:source_files], library_file: parameters[:library_file]
			end
		end
		
		define Rule, "build.dynamic-library" do
			input :source_files
			
			parameter :prefix
			parameter :static_library
			
			output :library_file, implicit: true do |arguments|
				arguments[:prefix] + "lib" + "lib#{arguments[:static_library]}.so"
			end
			
			apply do |parameters|
				# Make sure the output directory exists:
				fs.mkpath File.dirname(parameters[:library_file])
				
				build source_files: parameters[:source_files], library_file: parameters[:library_file]
			end
		end
		
		define Rule, "build.executable" do
			input :source_files
			
			parameter :prefix
			parameter :executable
			
			output :executable_file, implicit: true do |arguments|
				arguments[:prefix] + "bin" + arguments[:executable]
			end
			
			apply do |parameters|
				# Make sure the output directory exists:
				fs.mkpath File.dirname(parameters[:executable_file])
				
				build source_files: parameters[:source_files], executable_file: parameters[:executable_file]
			end
		end
		
		define Rule, "run.executable" do
			input :executable_path, implicit: true do |arguments|
				arguments[:prefix] + "bin" + arguments[:executable]
			end
			
			parameter :executable
			
			parameter :prefix
			parameter :args, optional: true
			
			apply do |parameters|
				run!(
					parameters[:executable_path],
					*parameters[:arguments]
				)
			end
		end
	end
end
