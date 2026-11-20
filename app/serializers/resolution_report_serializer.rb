class ResolutionReportSerializer
  include JSONAPI::Serializer

  set_type :resolution_report
  set_id :id

  attributes :prefix, :period

  attribute :summaryMetrics do |report|
    {
      totalAttemptedResolutions: report.total_attempted_resolutions,
      successfulResolutions: report.successful_resolutions,
      failedResolutions: report.failed_resolutions,
      totalUniqueDois: report.total_unique_dois,
      uniqueDoiSuccesses: report.unique_doi_successes,
      uniqueDoiFailures: report.unique_doi_failures,
      createdAt: report.created_at
    }
  end
end
