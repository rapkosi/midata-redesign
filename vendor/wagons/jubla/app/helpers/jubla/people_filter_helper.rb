module Jubla::PeopleFilterHelper
  
  def main_people_filter_links_with_alumni
    links = main_people_filter_links_without_alumni
    
    if can?(:index_full_people, @group) || can?(:index_local_people, @group) 
      links << link_to('Ehemalige', 
                       group_people_path(@group, 
                                         role_types: [Role::Alumnus.sti_name], 
                                         name: 'Ehemalige'))
    end
    
    links
  end
  
end