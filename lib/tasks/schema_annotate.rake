# frozen_string_literal: true

namespace :schema do
  desc "Add schema information as comments to model files (bottom of file, annotate-style)"
  task annotate: :environment do
    next unless Rails.env.development?

    puts "Adding schema information to model files..."

    models = []
    Dir[Rails.root.join("app", "models", "**", "*.rb")].each do |file|
      next if File.basename(file) == "application_record.rb"

      begin
        model_name = File.basename(file, ".rb").camelize
        model_class = model_name.constantize
        if model_class < ApplicationRecord && !model_class.abstract_class? && model_class.table_exists?
          models << { file: file, class: model_class }
        end
      rescue NameError, LoadError => e
        puts("Warning: Could not load model from #{file}: #{e.message}")
      end
    end

    puts "Found #{models.count} models to annotate"

    models.each do |model_info|
      file_path = model_info[:file]
      model_class = model_info[:class]

      puts("Annotating #{model_class.name} in #{file_path}")

      content = File.read(file_path)
      schema_comment = generate_schema_comment(model_class)
      content = remove_existing_schema_comment(content)
      content = add_schema_comment_at_bottom(content, schema_comment)
      File.write(file_path, content)

      puts("Annotated #{model_class.name}")
    rescue StandardError => e
      puts("Error annotating #{model_info[:class].name}: #{e.message}")
    end

    puts "\nSchema annotation completed!"
  end
end

def generate_schema_comment(model)
  table_name = model.table_name
  columns = model.connection.columns(table_name)
  indexes = model.connection.indexes(table_name)

  comment = []
  comment << "# == Schema Information"
  comment << "#"
  comment << "# Table name: #{table_name}"
  comment << "#"

  columns.each do |column|
    parts = []
    parts << (column.null ? "null" : "not null")
    parts << "primary key" if column.name == "id"
    if column.default.present?
      default_str = column.default.to_s
      default_str = "\"#{default_str}\"" if default_str.is_a?(String) && !default_str.start_with?("'")
      parts << "default(#{default_str})"
    end
    type_str = column.sql_type.include?("(") ? column.sql_type : column.type.to_s
    comment << "#  #{column.name.ljust(20)} :#{type_str.ljust(18)} #{parts.join(", ")}"
  end

  comment << "#"

  if indexes.any?
    comment << "# Indexes"
    comment << "#"
    indexes.each do |index|
      unique = index.unique ? " UNIQUE" : ""
      comment << "#  #{index.name} (#{index.columns.join(",")})#{unique}"
    end
    comment << "#"
  end

  comment.join("\n")
end

def remove_existing_schema_comment(content)
  lines = content.split("\n")
  filtered = []
  skip = false

  lines.each do |line|
    stripped = line.strip
    if stripped.start_with?("# == Schema Information") ||
       stripped.start_with?("# Table name:") ||
       (stripped.start_with?("#") && stripped.include?(":bigint") && stripped.include?("primary key"))
      skip = true
      next
    end
    if skip && (stripped.start_with?("#") || stripped.empty?)
      next
    end

    if skip && !stripped.start_with?("#") && !stripped.empty?
      skip = false
    end
    filtered << line unless skip
  end

  filtered.join("\n").gsub(/\n{3,}/, "\n\n")
end

def add_schema_comment_at_bottom(content, schema_comment)
  cleaned = content.rstrip
  cleaned + "\n\n" + schema_comment + "\n"
end

# Run schema:annotate after db:migrate in development
if Rails.env.development?
  Rake::Task["db:migrate"].enhance do
    Rake::Task["schema:annotate"].invoke
  end
end
