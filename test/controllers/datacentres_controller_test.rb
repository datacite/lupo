require 'test_helper'

class DatacentresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @datacentre = datacentres(:one)
  end

  test "should get index" do
    get datacentres_url, as: :json
    assert_response :success
  end

  test "should create datacentre" do
    assert_difference('datacentre.count') do
      post datacentres_url, params: { datacentre: { allocator: @datacentre.allocator, comments: @datacentre.comments, contact_email: @datacentre.contact_email, contact_name: @datacentre.contact_name, created: @datacentre.created, doi_quota_allowed: @datacentre.doi_quota_allowed, doi_quota_used: @datacentre.doi_quota_used, domains: @datacentre.domains, experiments: @datacentre.experiments, is_active: @datacentre.is_active, name: @datacentre.name, password: @datacentre.password, role_name: @datacentre.role_name, symbol: @datacentre.symbol, updated: @datacentre.updated, version: @datacentre.version } }, as: :json
    end

    assert_response 201
  end

  test "should show datacentre" do
    get datacentre_url(@datacentre), as: :json
    assert_response :success
  end

  test "should update datacentre" do
    patch datacentre_url(@datacentre), params: { datacentre: { allocator: @datacentre.allocator, comments: @datacentre.comments, contact_email: @datacentre.contact_email, contact_name: @datacentre.contact_name, created: @datacentre.created, doi_quota_allowed: @datacentre.doi_quota_allowed, doi_quota_used: @datacentre.doi_quota_used, domains: @datacentre.domains, experiments: @datacentre.experiments, is_active: @datacentre.is_active, name: @datacentre.name, password: @datacentre.password, role_name: @datacentre.role_name, symbol: @datacentre.symbol, updated: @datacentre.updated, version: @datacentre.version } }, as: :json
    assert_response 200
  end

  test "should destroy datacentre" do
    assert_difference('datacentre.count', -1) do
      delete datacentre_url(@datacentre), as: :json
    end

    assert_response 204
  end
end
