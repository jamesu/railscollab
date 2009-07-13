require 'test_helper'

class WikiPagesControllerTest < ActionController::TestCase
  def setup
    WikiPage.delete_all
  end

  test 'on GET to :index without pages' do
    get :index

    assert_response :success
    assert_template '3scale/wiki/pages/index'

    assert_select 'a[href=?]', new_wiki_page_path, 'New page'
    assert_select 'table.wiki_pages', false
  end

  test 'on GET to :index with pages' do
    setup_page
    get :index

    assert_response :success
    assert_equal [@page], assigns(:wiki_pages)

    assert_select 'table.wiki_pages tr' do
      assert_select 'td', 'Cool page'
      assert_select 'td' do
        assert_select 'a[href=?]', wiki_page_path(@page)
        assert_select 'a[href=?]', edit_wiki_page_path(@page)

        assert_select 'form[action=?][method=post]', wiki_page_path(@page) do
          assert_select 'input[type=hidden][name=_method][value=delete]'
          assert_select 'input[type=submit]'
        end
      end
    end
  end

  test 'on GET to :new' do
    get :new

    assert_response :success
    assert_template '3scale/wiki/pages/new'

    assert_not_nil assigns(:wiki_page)
    assert assigns(:wiki_page).new_record?
  end

  test 'on GET to :new with id' do
    get :new, :id => 'hello-world'

    assert_response :success
    assert_equal 'Hello world', assigns(:wiki_page).title
  end

  test 'on POST to :create' do
    assert_difference 'WikiPage.count', 1 do
      post :create, :wiki_page => { :title => 'Hello world' }
    end

    assert_response :redirect
    assert_redirected_to wiki_pages_url
  end

  test 'on GET to :show' do
    setup_page
    get :show, :id => @page.to_param

    assert_response :success
    assert_template '3scale/wiki/pages/show'
    assert_equal @page, assigns(:wiki_page)

    assert_select 'a[href=?]', wiki_page_path(:id => 'cool-content')
  end

  test 'on GET to :show if page does not exist' do
    get :show, :id => 'i-dont-exist'
    assert_response :not_found
    assert_template '3scale/wiki/pages/not_found'    
  end

  test 'on GET to :edit' do
    setup_page
    get :edit, :id => @page.to_param

    assert_response :success
    assert_template '3scale/wiki/pages/edit'
    assert_equal @page, assigns(:wiki_page)
  end

  test 'on PUT to :update' do
    setup_page
    put :update, :id => @page.to_param, :wiki_page => {:title => 'Even cooler page'}

    assert_equal @page, assigns(:wiki_page)
    assert_response :redirect
    assert_redirected_to wiki_pages_url

    @page.reload
    assert_equal @page.title, 'Even cooler page'
  end

  test 'on DELETE to :destroy' do
    setup_page

    assert_difference 'WikiPage.count', -1 do
      delete :destroy, :id => @page.to_param
    end

    assert_equal @page, assigns(:wiki_page)
    assert_response :redirect
    assert_redirected_to wiki_pages_url
  end

  test 'on POST to :preview with javascript' do
    xhr :post, :preview, :wiki_page => {:title => 'Hello world',
                                        :content => 'foo *bar*'}
    assert_response :success
    assert_template '3scale/wiki/pages/preview'

    assert_not_nil assigns(:wiki_page)
    assert_equal 'Hello world', assigns(:wiki_page).title
  end

  private

  def setup_page
    @page = WikiPage.create!(:title => 'Cool page', :content => 'Some [[cool content]]...')
  end
end
