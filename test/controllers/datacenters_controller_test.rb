require 'test_helper'

class DatacentersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @datacenter = datacenters(:one)
  end

  test "should get index" do
    get datacenters_url, as: :json
    assert_response :success
  end

  test "should create datacenter" do
    assert_difference('Datacenter.count') do
      post datacenters_url, params: { datacenter: { allocator: @datacenter.allocator, comments: @datacenter.comments, contact_email: @datacenter.contact_email, contact_name: @datacenter.contact_name, created: @datacenter.created, doi_quota_allowed: @datacenter.doi_quota_allowed, doi_quota_used: @datacenter.doi_quota_used, domains: @datacenter.domains, experiments: @datacenter.experiments, is_active: @datacenter.is_active, name: @datacenter.name, password: @datacenter.password, role_name: @datacenter.role_name, symbol: @datacenter.symbol, updated: @datacenter.updated, version: @datacenter.version } }, as: :json
    end

    assert_response 201
  end

  test "should show datacenter" do
    get datacenter_url(@datacenter), as: :json
    assert_response :success
  end

  test "should update datacenter" do
    patch datacenter_url(@datacenter), params: { datacenter: { allocator: @datacenter.allocator, comments: @datacenter.comments, contact_email: @datacenter.contact_email, contact_name: @datacenter.contact_name, created: @datacenter.created, doi_quota_allowed: @datacenter.doi_quota_allowed, doi_quota_used: @datacenter.doi_quota_used, domains: @datacenter.domains, experiments: @datacenter.experiments, is_active: @datacenter.is_active, name: @datacenter.name, password: @datacenter.password, role_name: @datacenter.role_name, symbol: @datacenter.symbol, updated: @datacenter.updated, version: @datacenter.version } }, as: :json
    assert_response 200
  end

  test "should destroy datacenter" do
    assert_difference('Datacenter.count', -1) do
      delete datacenter_url(@datacenter), as: :json
    end

    assert_response 204
  end
end
