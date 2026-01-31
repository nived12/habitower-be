# frozen_string_literal: true

##
# Errorable
# Concern for services that use ActiveModel::Errors. Provides the methods
# required by ActiveModel::Errors and a convenience valid? check.
#
# Usage: include in ApplicationService (or any service). Set @errors = ActiveModel::Errors.new(self)
# in initialize, then use errors.add(:base, "message") or errors.add(:field, "message").
#
module Errorable
  module ClassMethods
    def human_attribute_name(attr, _options = {})
      attr.to_s.humanize
    end

    def lookup_ancestors
      [self]
    end
  end

  def self.included(base)
    base.extend(ActiveModel::Naming)
    base.extend(ClassMethods)
  end

  def read_attribute_for_validation(attr)
    respond_to?(attr) ? send(attr) : nil
  end

  def valid?
    errors.empty?
  end
end
