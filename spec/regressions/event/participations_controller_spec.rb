# encoding:  utf-8

require 'spec_helper'

describe Event::ParticipationsController, type: :controller do

  # always use fixtures with crud controller examples, otherwise request reuse might produce errors
  let(:test_entry) { event_participations(:top) }
  
  let(:course) { test_entry.event }
  let(:group)  { course.groups.first }
  let(:event_base) { Fabricate(:event) }
  
  let(:test_entry_attrs) do
    { 
      additional_information: 'blalbalbalsbla',
      answers_attributes: [
        {answer: 'Halbtax', question_id: event_questions(:top_ov).id},
        {answer: 'nein',    question_id: event_questions(:top_vegi).id},
        {answer: 'Ne du',   question_id: event_questions(:top_more).id},
      ],
      application_attributes: { priority_2_id: nil }
    }
  end

  let(:scope_params) { {group_id: group.id, event_id: course.id} }

  before do 
    user = people(:top_leader)
    user.qualifications << Fabricate(:qualification, qualification_kind: qualification_kinds(:gl),
                                    start_at: course.dates.first.start_at) 
    sign_in(user) 
  end

  include_examples 'crud controller', skip: [%w(destroy)]

  describe_action :put, :update, :id => true do
    let(:params) { {model_identifier => test_attrs} }
    
    context ".html", :format => :html do
      context "with valid params", :combine => 'uhv' do
        it "updates answer attributes" do
          as = entry.answers
          as.detect {|a| a.question == event_questions(:top_ov) }.answer.should == 'Halbtax'
          as.detect {|a| a.question == event_questions(:top_vegi) }.answer.should == 'nein'
          as.detect {|a| a.question == event_questions(:top_more) }.answer.should == 'Ne du'
        end
      end
    end
  end

  describe "POST create" do
    [:event_base, :course].each do |event_sym|
      it "prompts to change contact data for #{event_sym}" do
        event = send(event_sym)
        post :create, group_id: group.id, event_id: event.id, participation: test_entry_attrs
        flash[:notice].should =~ /Bitte überprüfe die Kontaktdaten/
        should redirect_to group_event_participation_path(group, event, assigns(:participation))
      end
    end
  end

  describe "GET new" do
    subject { Capybara::Node::Simple.new(response.body) }
    [:event_base, :course].each do |event_sym|
      it "renders title for #{event_sym}" do
        event = send(event_sym)
        get :new, group_id: group.id, event_id: event.id
        should have_content "Anmeldung für #{event.name}"
      end
    end
    it "renders person field when passed for_someone_else param" do
      get :new, group_id: group.id, event_id: course.id, for_someone_else: true
      person_field = subject.all('form .control-group')[0]
      person_field.should have_content 'Person'
      person_field.should have_css('input', count: 2)
      person_field.all('input').first[:type].should eq 'hidden'
    end
  end

  describe_action :delete, :destroy, format: :html, id: true do
    it "redirects to application market" do
      should redirect_to group_event_application_market_index_path(group, course)
    end
    
    it "has flash noting the application" do
      flash[:notice].should =~ /Anmeldung/
    end
  end

  describe "GET print" do
    subject { response.body }
    let(:person) { Fabricate(:person_with_address) }
    let(:application) { Fabricate(:event_application, priority_1: test_entry.event, participation: test_entry) } 

    let(:dom) { Capybara::Node::Simple.new(response.body) }
    let(:contact_address) { dom.all('address').first }
    let(:particpant_address) { dom.all('address').last }

    before do
      test_entry.event.update_attribute(:contact, person)
      test_entry.update_attribute(:application, application)
    end

    it "renders participant and course contact" do
      get :print, group_id: group.id, event_id: test_entry.event.id, id: test_entry.id
      contact_address.text.should include person.address
      particpant_address.text.should include "bottom_member@example.com"
    end

    it "redirects users without permission" do
      sign_in(Fabricate(Group::BottomGroup::Member.name.to_s, group: groups(:bottom_group_one_one)).person)
      get :print, group_id: group.id, event_id: test_entry.event.id, id: test_entry.id
      should redirect_to root_url
    end
  end

  describe "participation role label filter" do

    let(:event) { events(:top_event) } 
    let(:parti1) { Fabricate(:event_participation, event: event) }
    let(:parti2) { Fabricate(:event_participation, event: event) }
    let(:parti3) { Fabricate(:event_participation, event: event) }

    let(:dom) { Capybara::Node::Simple.new(response.body) }

    before do
      Fabricate(Event::Role::Participant.name.to_sym, participation: parti1, label: 'Foolabel')
      Fabricate(Event::Role::Participant.name.to_sym, participation: parti2, label: 'Foolabel')
      Fabricate(Event::Role::Participant.name.to_sym, participation: parti3, label: 'Just label')
    end

    it "filters by event role label" do
      get :index, group_id: event.groups.first.id, event_id: event.id, filter: 'Foolabel'

      dom.should have_selector('a.dropdown-toggle', text: 'Foolabel')
      dom.should have_selector('.dropdown a', text: 'Foolabel')
      dom.should have_selector('.dropdown a', text: 'Just label')

      dom.should have_selector('a', text: parti1.person.to_s)
      dom.should have_selector('a', text: parti2.person.to_s)
      dom.should have_no_selector('a', text: parti3.person.to_s)

    end

  end
  
end
