require 'rails_helper'

RSpec.describe 'users/index', type: :view do
  before do
    assign(:users, [
      FactoryGirl.build_stubbed(:user, name: 'Вадик', balance: 5000),
      FactoryGirl.build_stubbed(:user, name: 'Миша', balance: 3000),
    ])

    render
  end

  context 'renders player names' do
    it 'show player with name "Вадик"' do
      expect(rendered).to match 'Вадик'
    end

    it 'show player with name "Миша"' do
      expect(rendered).to match 'Миша'
    end
  end

  context 'renders player balances' do
    it 'show first player balance' do
      expect(rendered).to match '5 000 ₽'
    end

    it 'show second player balance' do
      expect(rendered).to match '3 000 ₽'
    end
  end

  context 'renders player names in right order' do
    it 'show players in right order' do
      expect(rendered).to match /Вадик.*Миша/m
    end
  end
end
