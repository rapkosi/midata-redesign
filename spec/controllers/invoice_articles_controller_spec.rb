# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoiceArticlesController  do

  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }

  context 'authorization' do
    before { sign_in(person) }

    it "may index when person has finance permission on layer group" do
      get :index, group_id: group.id
      expect(response).to be_success
    end

    it "may edit when person has finance permission on layer group" do
      invoice = InvoiceArticle.create!(group: group, number: 1, name: 'test')
      get :edit, group_id: group.id, id: invoice.id
      expect(response).to be_success
    end

    it "may not index when person has no finance permission on layer group" do
      expect do
        get :index, group_id: groups(:top_layer).id
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not edit when person has no finance permission on layer group" do
      invoice = InvoiceArticle.create!(group: groups(:top_layer), number: 1, name: 'test')
      expect do
        get :edit, group_id: groups(:top_layer).id, id: invoice.id
      end.to raise_error(CanCan::AccessDenied)
    end
  end

end
