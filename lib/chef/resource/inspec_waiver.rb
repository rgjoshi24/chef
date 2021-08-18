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
    class InspecWaiver < Chef::Resource
      provides :inspec_waiver
      unified_mode true

      description "Use the **inspec_waiver** resource to add a waiver to the Compliance Phase."
      introduced "17.4"
      examples <<~DOC
      **Add an InSpec waiver to the Compliance Phase**:

      ```ruby
        inspec_waiver 'Add waiver entry for control' do
          control 'my_inspec_control_01'
          run_test false
          justification "The subject of this control is not managed by #{ChefUtils::Dist::Infra::PRODUCT} on the systems in policy group \#{node['policy_group']}"
          expiration '2022-01-01'
          action :add
        end
      ```

      **Add an InSpec waiver to the Compliance Phase using the 'name' property to identify the control**:

      ```ruby
        inspec_waiver 'my_inspec_control_01' do
          justification "The subject of this control is not managed by #{ChefUtils::Dist::Infra::PRODUCT} on the systems in policy group \#{node['policy_group']}"
          action :add
        end
      ```
      DOC

      property :control, String,
        name_property: true,
        description: "The name of the control being waived"

      property :expiration, String,
        description: "The expiration date of the waiver - provided in YYYY-MM-DD format",
        callbacks: {
          "Expiration date should be a valid calendar date and match the following format: YYYY-MM-DD" => proc { |e|
            re = Regexp.new('\d{4}-\d{2}-\d{2}$').freeze
            if re.match?(e)
              Date.valid_date?(*e.split("-").map(&:to_i))
            else
              e.nil?
            end
          },
        }

      property :run_test, [true, false],
        description: "If present and true, the control will run and be reported, but failures in it won’t make the overall run fail. If absent or false, the control will not be run."

      property :justification, String,
        description: "Can be any text you want and might include a reason for the waiver as well as who signed off on the waiver."

      property :source, [ Hash, String ]

      action :add do
        if run_context.waiver_collection.valid?(new_resource.control)
          include_waiver(new_resource.control)
        else
          include_waiver(waiver_hash)
        end
      end

      action_class do
        # If the source is nil and the control / name_property contains a file separator and is a string of a
        # file that exists, then use that as the file (similar to the package provider automatic source property).  Otherwise
        # just return the source.
        #
        # @api private
        def source
          @source ||=
            begin
              return new_resource.source unless new_resource.source.nil?
              return nil unless new_resource.control.count(::File::SEPARATOR) > 0 || (::File::ALT_SEPARATOR && new_resource.control.count(::File::ALT_SEPARATOR) > 0 )
              return nil unless ::File.exist?(new_resource.control)

              new_resource.control
            end
        end

        def waiver_hash
          case source
          when Hash
            source
          when String
            parse_file(source)
          when nil
            if new_resource.justification.nil? || new_resource.justification == ""
              raise Chef::Exceptions::ValidationFailed, "Entries for an InSpec waiver must have a justification given, this parameter must have a value."
            end

            control_hash = {}
            control_hash["expiration_date"] = new_resource.expiration.to_s unless new_resource.expiration.nil?
            control_hash["run"] = new_resource.run_test unless new_resource.run_test.nil?
            control_hash["justification"] = new_resource.justification.to_s

            { new_resource.control => control_hash }
          end
        end
      end
    end
  end
end
