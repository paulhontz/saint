module Saint

  module ORMFilters

    def limit limit, offset = nil
      {limit: limit}.merge(offset ? {offset: offset} : {})
    end

    def order map = {}
      order = map.keys.map { |c| c.send(map[c]) }.compact
      order.size > 0 ? {order: order} : {}
    end

    def eql column, val = nil
      {column => val}
    end

    def like column, val = nil
      {column.like => val}
    end

    def gt column, val = nil
      {column.gt => val}
    end

    def gte column, val = nil
      {column.gte => val}
    end

    def lt column, val = nil
      {column.lt => val}
    end

    def lte column, val = nil
      {column.lte => val}
    end

    def not column, val = nil
      {column.not => val}
    end

  end

  module ORMUtils
    class << self

      include ORMFilters

      def finalize
        DataMapper.finalize
      end
    end
  end

  module ORMMixin

    include ORMFilters

    attr_reader :model

    def initialize model, *node_instance_and_or_subset

      @model, @subset, @node_instance = model, Hash.new, nil
      node_instance_and_or_subset.each { |a| a.is_a?(Hash) ? @subset.update(a) : @node_instance = a }

      @before, @after = Hash.new, Hash.new
    end

    def first filters = {}
      db { model.first(filters.merge @subset) }
    end

    def first_or_create filters = {}
      db { model.first_or_create(filters.merge @subset) }
    end

    def filter filters = {}
      db { model.all(filters.merge @subset) }
    end

    def count filters = {}
      db { model.count(filters.merge @subset) }
    end

    def new data_set = {}
      db { model.new(data_set.merge @subset) }
    end

    def create data_set = {}
      db { model.create(data_set.merge @subset) }
    end

    def save row
      @subset.each_pair { |k, v| row[k] = v }
      return db(__method__, row) { row.save; row } if row.valid?
      [nil, row.errors]
    end

    def update row, data_set
      row.reload if row.dirty?
      row.save if row.new?
      data_set.merge(@subset).each_pair { |k, v| row[k] = v }
      return db(__method__, row) { row.save; row } if row.valid?
      [nil, row.errors]
    end

    # delete first found item vy given filters
    def delete filters = {}
      row, errors = db { model.first(filters.merge @subset) }
      return [row, errors] if errors.size > 0
      db(__method__, row) { row.destroy! }
    end

    # delete all found items by given filters
    def destroy filters = {}
      db(__method__) { model.all(filters.merge @subset).destroy! }
    end

    def storage_name
      model.storage_name
    end

    def properties
      model.properties.map { |p| p.name }
    end

    def subset subset
      @subset = subset
    end

    # define callbacks to be executed before given actions,
    # or before/after any action if no actions given.
    def before *actions, &proc
      if proc
        actions = ['*'] if actions.size == 0
        actions.each { |a| @before[a] = proc }
      end
      @before
    end

    # (see #before)
    def after *actions, &proc
      if proc
        actions = ['*'] if actions.size == 0
        actions.each { |a| @after[a] = proc }
      end
      @after
    end

    private

    def db operation = nil, row = nil, &proc
      errors = Array.new
      scope = @node_instance || self
      begin

        if row
          before.select { |c| [operation, '*'].include?(c[0]) }.each do |c|
            scope.instance_exec row, operation, &c[1]
          end
        end

        result = proc.call

        unless operation == :delete
          if row
            after.select { |c| [operation, '*'].include?(c[0]) }.each do |c|
              scope.instance_exec row, operation, &c[1]
            end
          end
        end

      rescue => e
        if e.respond_to?(:each_pair)
          e.each_pair do |k, v|
            k = k.is_a?(Array) ? k.join(", ") : k.to_s
            v = v.is_a?(Array) ? v.join(", ") : v.to_s
            errors << [k, v].join(": ")
          end
        elsif e.respond_to?(:each)
          e.each { |err| errors << err }
        else
          errors = [e.to_s]
        end
      end
      [result, errors]
    end

  end

  class ORM
    include Saint::ORMMixin
  end

end
