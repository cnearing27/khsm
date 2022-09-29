require 'rails_helper'

RSpec.feature "USER watches another's profile", type: :feature do
  let(:user) { FactoryGirl.create :user }
  let(:another_user) { FactoryGirl.create :user }

  let!(:games) do
    [ FactoryGirl.create(:game, user: another_user, created_at: Time.now, current_level: 1),
      FactoryGirl.create(:game, user: another_user, created_at: '2022-06-26 19:07:00', finished_at: '2022-06-26 19:08:08',
        current_level: 5, prize: 12345) ]
  end

  before { login_as user }

  scenario 'successfully' do
    visit "/users/#{another_user.id}"

    expect(page).not_to have_content 'Сменить имя и пароль'

    expect(page).to have_content 'Жора'

    expect(page).to have_content 'в процессе'
    expect(page).to have_content '0 ₽'
    expect(page).to have_content '50/50'

    expect(page).to have_content '26 июня, 19:07'
    expect(page).to have_content 'деньги'
    expect(page).to have_content '12 345 ₽'
  end
end
