require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:new_user) { FactoryGirl.create(:user) }

  context 'when registered user' do
    before do
      sign_in new_user
      assign(:user, new_user)
      assign(:games, [FactoryGirl.create(:game)])

      stub_template 'users/_game.html.erb' => 'User game goes here'
      render
    end

    it 'show player name' do
      expect(rendered).to match(new_user.name)
    end

    it 'show change password button' do
      expect(rendered).to match('Сменить имя и парол')
    end

    it 'show user games' do
      expect(rendered).to match('User game goes here')
    end
  end

  context 'when anonymous user' do
    before do
      assign(:user, new_user)

      render
    end

    it 'not show change password button' do
      expect(rendered).not_to match('Сменить имя и парол')
    end
  end
end
