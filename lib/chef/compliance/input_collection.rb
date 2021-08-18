# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
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

require_relative "input"

class Chef
  module Compliance
    class InputCollection < Array

      # Event dispatcher for this run.
      #
      # @return [Chef::EventDispatch::Dispatcher]
      #
      attr_reader :events

      # @return [Hash] Hash of raw values (not from files)
      attr_reader :raw_hash

      def initialize(events)
        @events = events
        @raw_hash = {}
      end

      # Add a input to the input collection.  The cookbook_name needs to be determined by the
      # caller and is used in the `include_input` API to match on.  The path should be the complete
      # path on the host of the yml file, including the filename.
      #
      # @param path [String]
      # @param cookbook_name [String]
      #
      def from_file(filename, cookbook_name)
        new_input = Input.from_file(events, filename, cookbook_name)
        self << new_input
        events.compliance_input_loaded(cookbook_name, new_input.pathname, filename)
      end

      # @return [Array<Input>] inspec inputs which are enabled in a form suitable to pass to inspec
      #
      def for_inspec
        select(&:enabled?).each_with_object([]) { |input, arry| arry << input.for_inspec }
      end

      # DSL method to enable input files.  This matches on the name of the control being waived, it
      # does not match on the filename of the input file.
      #
      # @example Specific input file in a cookbook
      #
      # include_input "acme_cookbook::ssh-001"
      #
      # @example Every input file in a cookbook
      #
      # include_input "acme_cookbook"
      #
      # @example Matching inputs by regexp in a cookbook
      #
      # include_input "acme_cookbook::ssh.*"
      #
      # @example Matching inputs by regexp in any cookbook in the cookbook collection
      #
      # include_input ".*::ssh.*"
      #
      def include_input(arg)
        raise "include_input was given a nil value" if arg.nil?

        # if we're given a hash argument just shove it in the raw_hash
        if arg.is_a?(Hash)
          raw_hash.merge!(arg)
          return
        end

        matching_inputs(arg).each(&:enable!)
      end

      def valid?(arg)
        !matching_inputs(arg).empty?
      end

      HIDDEN_IVARS = [ :@events ].freeze

      # Omit the event object from error output
      #
      def inspect
        ivar_string = (instance_variables.map(&:to_sym) - HIDDEN_IVARS).map do |ivar|
          "#{ivar}=#{instance_variable_get(ivar).inspect}"
        end.join(", ")
        "#<#{self.class}:#{object_id} #{ivar_string}>"
      end

      private

      def matching_inputs(arg, should_raise: false)
        (cookbook_name, input_name) = arg.split("::")

        input_name = "default" if input_name.nil?

        inputs = select { |input| /^#{cookbook_name}$/.match?(input.cookbook_name) && /^#{input_name}$/.match?(input.pathname) }

        if inputs.empty? && should_raise
          raise "No inspec inputs matching '#{input_name}' found in cookbooks matching '#{cookbook_name}'"
        end

        inputs
      end

      def matching_inputs!(arg)
        matching_inputs(arg, should_raise: true)
      end
    end
  end
end
