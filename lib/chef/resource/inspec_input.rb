#
# Copyright:: Copyright (c) Chef Software Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../resource"

class Chef
  class Resource
    class InspecInput < Chef::Resource
      provides :inspec_input
      unified_mode true

      description "Use the **inspec_input** resource to add an input to the Compliance Phase."
      introduced "17.4"
      examples <<~DOC
      **Add an InSpec input to the Compliance Phase**:

      ```ruby
        inspec_input { ssh_custom_path: '/whatever2' }
      ```

      **Add an InSpec waiver to the Compliance Phase using the 'name' property to identify the input**:

      ```ruby
        inspec_input "setting my input" do
          source( { ssh_custom_path: '/whatever2' })
        end
      ```

      **Add an InSpec waiver to the Compliance Phase using a TOML, JSON or YAML file**:

      ```ruby
        inspec_input "/path/to/my/input.yml"
      ```

      **Add an InSpec waiver to the Compliance Phase using a TOML, JSON or YAML file, using the 'name' property**:

      ```ruby
        inspec_input "setting my input" do
          source "/path/to/my/input.yml"
        end
      ```
      DOC

      property :name, [ Hash, String ]

      property :source, [ Hash, String ],
        name_property: true

      action :add do
        if run_context.input_collection.valid?(new_resource.source)
          include_input(new_resource.source)
        else
          include_input(input_hash)
        end
      end

      action_class do
        def input_hash
          case new_resource.source
          when Hash
            new_resource.source
          when String
            parse_file(new_resource.source)
          end
        end
      end
    end
  end
end
