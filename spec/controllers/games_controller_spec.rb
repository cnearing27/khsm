require 'rails_helper'

require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryGirl.create(:user) }
  # админ
  let(:admin) { FactoryGirl.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  describe '#create' do
    context 'when registered user' do
      before { sign_in user }

      context 'creates game' do
        before { post :create }

        let(:game) { assigns(:game) }

        it 'game is not finished' do
          expect(game.finished?).to be false
        end

        it 'right game user' do
          expect(game.user).to eq(user)
        end

        it 'redirect to game page' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'takes notice' do
          expect(flash[:notice]).to be
        end
      end

      it 'create second game' do
        expect(game_w_questions.finished?).to be_falsey
        expect { post :create }.to change(Game, :count).by(0)
        game = assigns(:game)
        expect(game).to be_nil
        expect(response).to redirect_to(game_path(game_w_questions))
        expect(flash[:alert]).to be
      end

  #    context 'create second game' do
  #      before { post :create }
  #
  #      it 'user has active game' do
  #        expect(game_w_questions.finished?).to be_falsey
  #      end
#
  #      it 'games count is not changed' do
  #        expect { post :create }.to change(Game, :count).by(0)
  #      end
#
  #      let(:game) { assigns(:game) }
#
  #      it 'game is nil' do
  #        expect(game).to be_nil
  #      end
#
  #      it 'redirect to active game page' do
  #        expect(response).to redirect_to(game_path(game_w_questions))
  #      end
#
  #      it 'takes alert' do
  #        expect(flash[:alert]).to be
  #      end
  #    end
    end

    context 'when anonymous' do
      context 'creates game' do
        before { post :create }

        it "don't create new game" do
          expect change(Game, :count).by(0)
        end

        it 'responce status is not 200' do
          expect(response.status).not_to eq(200)
        end

        it 'redirect to sign in' do
          expect(response).to redirect_to(new_user_session_path)
        end

        it 'takes alert' do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#show' do
    context 'when registered user' do
      before { sign_in user }

      context 'see his own game' do
        before { get :show, id: game_w_questions.id }

        let(:game) { assigns(:game) }

        it 'game is not finished' do
          expect(game.finished?).to be_falsey
        end

        it 'right game user' do
          expect(game.user).to eq(user)
        end

        it 'return right response status' do
          expect(response.status).to eq(200)
        end

        it 'render right template' do
          expect(response).to render_template('show')
        end
      end

      context "want to see another's game" do
        let(:anothers_game) { FactoryGirl.create(:game_with_questions) }

        before { get :show, id: anothers_game.id }

        it 'return right response status' do
          expect(response.status).not_to eq(200)
        end

        it 'redirect to main page' do
          expect(response).to redirect_to(root_path)
        end

        it 'takes alert' do
          expect(flash[:alert]).to be
        end
      end
    end

    context 'when anonymous' do
      context "want to see another's game" do
        before { get :show, id: game_w_questions.id }

        it 'return right response status' do
          expect(response.status).not_to eq(200)
        end

        it 'redirect to sign in page' do
          expect(response).to redirect_to(new_user_session_path)
        end

        it 'takes alert' do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe "#answer" do
    context 'when registered user' do
      before { sign_in user }

      context 'takes right answer' do
        before { put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key }
        let(:game) { assigns(:game) }

        it 'game is not finished' do
          expect(game.finished?).to be_falsey
        end

        it 'game level > 0' do
          expect(game.current_level).to be > 0
        end

        it 'redirect to game page' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'not contain some notice/alert' do
          expect(flash.empty?).to be_truthy
        end
      end

      context 'takes incorrect answer' do
        let(:game) { assigns(:game) }

        let(:incorrect_answer_key) do
          ['a', 'b', 'c', 'd'].
          reject { |letter| letter == game_w_questions.current_game_question.correct_answer_key }.sample
        end

        before { put :answer, id: game_w_questions.id, letter: incorrect_answer_key }

        it 'is not correct answer' do
          answer_is_correct = assigns(:answer_is_correct)
          expect(answer_is_correct).to be_falsey
        end

        it 'end the game' do
          expect(game.finished?).to be_truthy
        end

        it 'game status is fail' do
          expect(game.status).to be :fail
        end

        it 'redirect to user profile' do
          expect(response).to redirect_to(user_path(user))
        end

        it 'takes alert' do
          expect(flash[:alert]).to be
        end
      end
    end

    context 'when anonymous trying answer' do
      before { put :answer, id: game_w_questions.id }
      it 'responce status is not 200' do
        expect(response.status).not_to eq(200)
      end
      it 'redirect to sign in' do
        expect(response).to redirect_to(new_user_session_path)
      end
      it 'takes alert' do
        expect(flash[:alert]).to be
      end
    end
  end

  describe "#take_money" do
    context 'when registered user takes money before the game ends' do
      before do
        sign_in user
        game_w_questions.update_attributes(current_level: 5)
        put :take_money, id: game_w_questions.id
      end

      let(:game) { assigns(:game) }

      it 'game is finished' do
        expect(game.finished?).to be_truthy
      end

      it 'game prize = 1000' do
        expect(game.prize).to eq 1000
      end

      it 'redirect to user profile' do
        expect(response).to redirect_to(user_path(user))
      end

      it 'increase user balance by 1000' do
        user.reload
        expect(user.balance).to eq 1000
      end

      it 'not contain some notice/alert' do
        expect(flash.empty?).to be_falsey
      end
    end

    context 'when anonymous trying answer' do
      before { put :take_money, id: game_w_questions.id }

      it 'responce status is not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to sign in' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'takes alert' do
        expect(flash[:alert]).to be
      end
    end
  end

  describe '#help' do
    before { sign_in user }

    it 'uses audience help' do
      # Проверяем, что у текущего вопроса нет подсказок
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      # И подсказка не использована
      expect(game_w_questions.audience_help_used).to be_falsey

      # Пишем запрос в контроллер с нужным типом (put — не создаёт новых сущностей, но что-то меняет)
      put :help, id: game_w_questions.id, help_type: :audience_help
      game = assigns(:game)

      # Проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be_falsey
      expect(game.audience_help_used).to be_truthy
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end
  end
end

