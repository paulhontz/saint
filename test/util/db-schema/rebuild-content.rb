require File.expand_path('../../../load', __FILE__)

DataMapper.finalize

module Model
  MenuPage.destroy!
  Menu.destroy!
  Page.destroy!
  Author.destroy!
  Country.destroy!
  Options.destroy!
end

countries = []
%w[
Austria
Belgium
Denmark
Finland
France
Germany
Poland
Portugal
Romania
Russia
United_Kingdom
United_States
].each do |c|
  countries << Model::Country.create(name: c)
end

left_menu = Model::Menu.create name: 'left'
top_menu = Model::Menu.create name: 'top'

pages = []
1.upto([rand(50), rand(100)].sample) do |a|
  author = Model::Author.create name: 'Author Nr%s' % a, country: countries.sample
  1.upto([rand(5), rand(10)].sample) do |p|
    page = Model::Page.create name: ('Page Nr%s.%s' % [p, a]), author: author
    page.menus << [left_menu, top_menu].sample
    page.active = rand(100_000) % 2
    if (rand(1000) % 2 + rand(1000) % 2 + rand(1000) % 2) == 0
      pages.sample(rand(5)).each { |c| page.children << c }
    end
    page.save
    pages << page
  end
end
