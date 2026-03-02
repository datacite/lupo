# frozen_string_literal: true

require "rails_helper"

describe Doi, type: :model, vcr: true, elasticsearch: false, prefix_pool_size: 1 do
  it_behaves_like "an STI class"

  describe "validations" do
    it { should validate_presence_of(:doi) }
  end

  describe "validate doi" do
    it "using base32 crockford checksum =" do
      subject = build(:doi, doi: "10.18730/nvb5=")
      expect(subject).to be_valid
    end

    it "using base32 crockford checksum $" do
      subject = build(:doi, doi: "10.18730/nvb4$")
      expect(subject).to be_valid
    end

    it "using base32 crockford checksum ~" do
      subject = build(:doi, doi: "10.18730/nvb3~")
      expect(subject).to be_valid
    end

    it "using base32 crockford checksum *" do
      subject = build(:doi, doi: "10.18730/nvb2*")
      expect(subject).to be_valid
    end
  end

  describe "after_commit" do
    let(:doi) { create(:doi, aasm_state: "findable") }
    let(:sqs_client) { instance_double(Aws::SQS::Client) }

    before do
      allow_any_instance_of(DataciteDoi).to receive(:send_message)
      allow(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
      allow(IndexJob).to receive(:perform_later)
      allow(DataciteDoi).to receive_message_chain(:__elasticsearch__, :index_document)
    end

    context "On Update event" do
      it "sends import message if relevant attributes are modified" do
        travel_to(Time.zone.local(2023, 12, 14, 10, 7, 40)) do
          expect(doi).to receive(:send_import_message).with(doi.to_jsonapi)

          doi.update(related_identifiers: [{ "relatedIdentifier" => "new_identifier", "relatedIdentifierType" => "DOI", "relationType" => "IsPartOf" }])
        end
      end

      it "sends import message if creators are modified" do
        travel_to(Time.zone.local(2023, 12, 14, 10, 7, 40)) do
          expect(doi).to receive(:send_import_message).with(doi.to_jsonapi)

          doi.update(creators: [{ "nameType" => "Personal", "name" => "New Creator" }])
        end
      end

      it "sends import message if funding_references are modified" do
        travel_to(Time.zone.local(2023, 12, 14, 10, 7, 40)) do
          expect(doi).to receive(:send_import_message).with(doi.to_jsonapi)

          doi.update(funding_references: [{ "funder" => "New Funder", "title" => "New Title" }])
        end
      end

      it "does not send import message if no relevant attributes are modified" do
        expect(doi).not_to receive(:send_import_message)

        doi.update(titles: "New Title")
      end

      it "does not send import message if aasm_state is not 'findable'" do
        expect(doi).not_to receive(:send_import_message)

        doi.update(aasm_state: "draft")
      end

      it "does not send import message after create if aasm_state is not 'findable'" do
        new_doi = create(:doi, aasm_state: "draft")

        expect(new_doi).not_to receive(:send_import_message)
      end

      it "does not send import message when environment variable EXCLUDE_PREFIXES_FROM_DATA_IMPORT is set to prefix of doi" do
        ENV["EXCLUDE_PREFIXES_FROM_DATA_IMPORT"] = "10.18730"
        new_doi = create(:doi, doi: "10.18730/nvb5=", aasm_state: "findable")

        expect(new_doi).not_to receive(:send_import_message)
      end
    end

    context "On Create event" do
      it "sends import message after create if aasm_state is 'findable'" do
        travel_to(Time.zone.local(2023, 12, 14, 10, 7, 40)) do
          new_doi = build(:doi, aasm_state: "findable")
          allow(new_doi).to receive(:send_import_message)
          new_doi.save!

          # Sleep for a short duration to ensure the asynchronous after_commit has completed
          sleep 1

          expect(new_doi).to have_received(:send_import_message).with(new_doi.to_jsonapi)
        end
      end

      it "does not send import message after create if aasm_state is not 'findable'" do
        travel_to(Time.zone.local(2023, 12, 14, 10, 7, 40)) do
          new_doi = create(:doi, aasm_state: "draft")

          expect(new_doi).not_to receive(:send_import_message)
        end
      end
    end
  end

  describe "validate agency" do
    it "DataCite" do
      subject = build(:doi, agency: "DataCite")
      expect(subject).to be_valid
      expect(subject.agency).to eq("datacite")
    end

    it "datacite" do
      subject = build(:doi, agency: "Datacite")
      expect(subject).to be_valid
      expect(subject.agency).to eq("datacite")
    end

    it "Crossref" do
      subject = build(:doi, agency: "Crossref")
      expect(subject).to be_valid
      expect(subject.agency).to eq("crossref")
    end

    it "Crossref" do
      subject = build(:doi, agency: "crossref")
      expect(subject).to be_valid
      expect(subject.agency).to eq("crossref")
    end

    it "KISTI" do
      subject = build(:doi, agency: "kisti")
      expect(subject).to be_valid
      expect(subject.agency).to eq("kisti")
    end

    it "mEDRA" do
      subject = build(:doi, agency: "medra")
      expect(subject).to be_valid
      expect(subject.agency).to eq("medra")
    end

    it "ISTIC" do
      subject = build(:doi, agency: "istic")
      expect(subject).to be_valid
      expect(subject.agency).to eq("istic")
    end

    it "JaLC" do
      subject = build(:doi, agency: "jalc")
      expect(subject).to be_valid
      expect(subject.agency).to eq("jalc")
    end

    it "Airiti" do
      subject = build(:doi, agency: "airiti")
      expect(subject).to be_valid
      expect(subject.agency).to eq("airiti")
    end

    it "CNKI" do
      subject = build(:doi, agency: "cnki")
      expect(subject).to be_valid
      expect(subject.agency).to eq("cnki")
    end

    it "OP" do
      subject = build(:doi, agency: "op")
      expect(subject).to be_valid
      expect(subject.agency).to eq("op")
    end

    it "XXX" do
      subject = build(:doi, agency: "xxx")
      expect(subject).to be_valid
      expect(subject.agency).to eq("datacite")
    end

    it "default" do
      subject = build(:doi)
      expect(subject).to be_valid
      expect(subject.agency).to eq("datacite")
    end
  end

  describe "state" do
    subject { create(:doi) }

    describe "draft" do
      it "default" do
        expect(subject).to have_state(:draft)
      end
    end

    describe "registered" do
      it "can register" do
        subject.register
        expect(subject).to have_state(:registered)
      end
    end

    describe "findable" do
      it "can publish" do
        subject.publish
        expect(subject).to have_state(:findable)
      end
    end

    describe "flagged" do
      it "can flag" do
        subject.publish
        subject.flag
        expect(subject).to have_state(:flagged)
      end

      it "can't flag if draft" do
        subject.flag
        expect(subject).to have_state(:draft)
      end
    end

    describe "broken" do
      it "can link_check" do
        subject.publish
        subject.link_check
        expect(subject).to have_state(:broken)
      end

      it "can't link_check if draft" do
        subject.link_check
        expect(subject).to have_state(:draft)
      end
    end
  end

  describe "url" do
    it "can handle long urls" do
      url = "http://core.tdar.org/document/365177/new-york-african-burial-ground-skeletal-biology-final-report-volume-1-chapter-5-origins-of-the-new-york-african-burial-ground-population-biological-evidence-of-geographical-and-macroethnic-affiliations-using-craniometrics-dental-morphology-and-preliminary-genetic-analysis"
      subject = create(:doi, url: url)
      expect(subject.url).to eq(url)
    end

    it "can handle ftp urls" do
      url = "ftp://ftp.library.noaa.gov/noaa_documents.lib/NESDIS/GSICS_quarterly/v1_no2_2007.pdf"
      subject = create(:doi, url: url)
      expect(subject.url).to eq(url)
    end
  end

  describe "update_url" do
    let(:token) { User.generate_token(role_id: "client_admin") }
    let(:current_user) { User.new(token) }

    context "draft doi" do
      let(:provider) { create(:provider, symbol: "ADMIN") }
      let(:client) { create(:client, provider: provider) }
      let(:url) { "https://www.example.org" }
      subject { build(:doi, client: client, current_user: current_user) }

      it "don't update state change" do
        expect(subject).to have_state(:draft)
      end
    end

    context "registered doi" do
      let(:provider) { create(:provider, symbol: "ADMIN") }
      let(:client) { create(:client, provider: provider) }
      let(:url) { "https://www.example.org" }
      subject { build(:doi, client: client, current_user: current_user) }

      it "update state change" do
        subject.register
        expect(subject).to have_state(:registered)
      end
    end

    context "findable doi" do
      let(:provider)  { create(:provider, symbol: "ADMIN") }
      let(:client) { create(:client, provider: provider) }
      let(:url) { "https://www.example.org" }
      subject { build(:doi, client: client, current_user: current_user) }

      it "update state change" do
        subject.publish
        expect(subject).to have_state(:findable)
      end
    end

    context "provider europ" do
      let(:provider)  { create(:provider, symbol: "EUROP") }
      let(:client) { create(:client, provider: provider) }
      let(:url) { "https://www.example.org" }
      subject { build(:doi, client: client, current_user: current_user) }

      it "don't update state change" do
        subject.publish
        expect(subject).to have_state(:findable)
      end
    end

    context "no current_user" do
      let(:provider) { create(:provider, symbol: "ADMIN") }
      let(:client) { create(:client, provider: provider) }
      let(:url) { "https://www.example.org" }
      subject { build(:doi, client: client, current_user: nil) }

      it "don't update state change" do
        subject.publish
        expect(subject).to have_state(:findable)
      end
    end
  end

  describe "descriptions" do
    let(:doi) { build(:doi) }

    it "hash" do
      doi.descriptions = [{ "description" => "This is a description." }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "string" do
      doi.descriptions = ["This is a description."]
      expect(doi.save).to be false
      expect(doi.errors.details).to eq(descriptions: [{ error: "Description 'This is a description.' should be an object instead of a string." }])
    end
  end

  describe "language" do
    let(:doi) { build(:doi) }

    it "iso 639-1" do
      doi.language = "fr"
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.language).to eq("fr")
    end

    it "iso 639-2" do
      doi.language = "fra"
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.language).to eq("fr")
    end

    it "human" do
      doi.language = "french"
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.language).to eq("fr")
    end

    it "human longer than 8 characters" do
      doi.language = "Indonesian"
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.language).to eq("id")
    end

    it "non-iso 639-1" do
      doi.language = "hhh"
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.language).to eq("hhh")
    end

    it "non-iso 639-1 with country code" do
      doi.language = "prq-PE"
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.language).to eq("prq-PE")
    end

    it "fails xs:language regex" do
      doi.language = "Borgesian"
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.language).to be_nil
    end

    it "nil" do
      doi.language = nil
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end
  end

  describe "rights_list" do
    let(:doi) { build(:doi) }

    it "string" do
      doi.rights_list = ["Creative Commons Attribution 4.0 International license (CC BY 4.0)"]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.rights_list).to eq([{ "rights" => "Creative Commons Attribution 4.0 International license (CC BY 4.0)" }])
    end

    it "hash rights" do
      doi.rights_list = [{ "rights" => "Creative Commons Attribution 4.0 International license (CC BY 4.0)" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.rights_list).to eq([{ "rights" => "Creative Commons Attribution 4.0 International license (CC BY 4.0)" }])
    end

    it "hash rights too long" do
      rights = <<-GPL
      Copyright (C) 2020  Alejandro Strachan\n\nThis program is free software: you can redistribute it and/or modify\nit under the terms of the GNU General Public License as published by\nthe Free Software Foundation, either version 3 of the License, or\n(at your option) any later version.\n\nThis program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\nGNU General Public License below for more details.\n\n------------------------------------------------------------------------\n\n                    GNU GENERAL PUBLIC LICENSE\n                       Version 3, 29 June 2007\n\n Copyright (C) 2007 Free Software Foundation, Inc. \n Everyone is permitted to copy and distribute verbatim copies\n of this license document, but changing it is not allowed.\n\n                            Preamble\n\n  The GNU General Public License is a free, copyleft license for\nsoftware and other kinds of works.\n\n  The licenses for most software and other practical works are designed\nto take away your freedom to share and change the works.  By contrast,\nthe GNU General Public License is intended to guarantee your freedom to\nshare and change all versions of a program--to make sure it remains free\nsoftware for all its users.  We, the Free Software Foundation, use the\nGNU General Public License for most of our software; it applies also to\nany other work released this way by its authors.  You can apply it to\nyour programs, too.\n\n  When we speak of free software, we are referring to freedom, not\nprice.  Our General Public Licenses are designed to make sure that you\nhave the freedom to distribute copies of free software (and charge for\nthem if you wish), that you receive source code or can get it if you\nwant it, that you can change the software or use pieces of it in new\nfree programs, and that you know you can do these things.\n\n  To protect your rights, we need to prevent others from denying you\nthese rights or asking you to surrender the rights.  Therefore, you have\ncertain responsibilities if you distribute copies of the software, or if\nyou modify it: responsibilities to respect the freedom of others.\n\n  For example, if you distribute copies of such a program, whether\ngratis or for a fee, you must pass on to the recipients the same\nfreedoms that you received.  You must make sure that they, too, receive\nor can get the source code.  And you must show them these terms so they\nknow their rights.\n\n  Developers that use the GNU GPL protect your rights with two steps:\n(1) assert copyright on the software, and (2) offer you this License\ngiving you legal permission to copy, distribute and/or modify it.\n\n  For the developers' and authors' protection, the GPL clearly explains\nthat there is no warranty for this free software.  For both users' and\nauthors' sake, the GPL requires that modified versions be marked as\nchanged, so that their problems will not be attributed erroneously to\nauthors of previous versions.\n\n  Some devices are designed to deny users access to install or run\nmodified versions of the software inside them, although the manufacturer\ncan do so.  This is fundamentally incompatible with the aim of\nprotecting users' freedom to change the software.  The systematic\npattern of such abuse occurs in the area of products for individuals to\nuse, which is precisely where it is most unacceptable.  Therefore, we\nhave designed this version of the GPL to prohibit the practice for those\nproducts.  If such problems arise substantially in other domains, we\nstand ready to extend this provision to those domains in future versions\nof the GPL, as needed to protect the freedom of users.\n\n  Finally, every program is threatened constantly by software patents.\nStates should not allow patents to restrict development and use of\nsoftware on general-purpose computers, but in those that do, we wish to\navoid the special danger that patents applied to a free program could\nmake it effectively proprietary.  To prevent this, the GPL assures that\npatents cannot be used to render the program non-free.\n\n  The precise terms and conditions for copying, distribution and\nmodification follow.\n\n                       TERMS AND CONDITIONS\n\n  0. Definitions.\n\n  &amp;quot;This License&amp;quot; refers to version 3 of the GNU General Public License.\n\n  &amp;quot;Copyright&amp;quot; also means copyright-like laws that apply to other kinds of\nworks, such as semiconductor masks.\n\n  &amp;quot;The Program&amp;quot; refers to any copyrightable work licensed under this\nLicense.  Each licensee is addressed as &amp;quot;you&amp;quot;.  &amp;quot;Licensees&amp;quot; and\n&amp;quot;recipients&amp;quot; may be individuals or organizations.\n\n  To &amp;quot;modify&amp;quot; a work means to copy from or adapt all or part of the work\nin a fashion requiring copyright permission, other than the making of an\nexact copy.  The resulting work is called a &amp;quot;modified version&amp;quot; of the\nearlier work or a work &amp;quot;based on&amp;quot; the earlier work.\n\n  A &amp;quot;covered work&amp;quot; means either the unmodified Program or a work based\non the Program.\n\n  To &amp;quot;propagate&amp;quot; a work means to do anything with it that, without\npermission, would make you directly or secondarily liable for\ninfringement under applicable copyright law, except executing it on a\ncomputer or modifying a private copy.  Propagation includes copying,\ndistribution (with or without modification), making available to the\npublic, and in some countries other activities as well.\n\n  To &amp;quot;convey&amp;quot; a work means any kind of propagation that enables other\nparties to make or receive copies.  Mere interaction with a user through\na computer network, with no transfer of a copy, is not conveying.\n\n  An interactive user interface displays &amp;quot;Appropriate Legal Notices&amp;quot;\nto the extent that it includes a convenient and prominently visible\nfeature that (1) displays an appropriate copyright notice, and (2)\ntells the user that there is no warranty for the work (except to the\nextent that warranties are provided), that licensees may convey the\nwork under this License, and how to view a copy of this License.  If\nthe interface presents a list of user commands or options, such as a\nmenu, a prominent item in the list meets this criterion.\n\n  1. Source Code.\n\n  The &amp;quot;source code&amp;quot; for a work means the preferred form of the work\nfor making modifications to it.  &amp;quot;Object code&amp;quot; means any non-source\nform of a work.\n\n  A &amp;quot;Standard Interface&amp;quot; means an interface that either is an official\nstandard defined by a recognized standards body, or, in the case of\ninterfaces specified for a particular programming language, one that\nis widely used among developers working in that language.\n\n  The &amp;quot;System Libraries&amp;quot; of an executable work include anything, other\nthan the work as a whole, that (a) is included in the normal form of\npackaging a Major Component, but which is not part of that Major\nComponent, and (b) serves only to enable use of the work with that\nMajor Component, or to implement a Standard Interface for which an\nimplementation is available to the public in source code form.  A\n&amp;quot;Major Component&amp;quot;, in this context, means a major essential component\n(kernel, window system, and so on) of the specific operating system\n(if any) on which the executable work runs, or a compiler used to\nproduce the work, or an object code interpreter used to run it.\n\n  The &amp;quot;Corresponding Source&amp;quot; for a work in object code form means all\nthe source code needed to generate, install, and (for an executable\nwork) run the object code and to modify the work, including scripts to\ncontrol those activities.  However, it does not include the work's\nSystem Libraries, or general-purpose tools or generally available free\nprograms which are used unmodified in performing those activities but\nwhich are not part of the work.  For example, Corresponding Source\nincludes interface definition files associated with source files for\nthe work, and the source code for shared libraries and dynamically\nlinked subprograms that the work is specifically designed to require,\nsuch as by intimate data communication or control flow between those\nsubprograms and other parts of the work.\n\n  The Corresponding Source need not include anything that users\ncan regenerate automatically from other parts of the Corresponding\nSource.\n\n  The Corresponding Source for a work in source code form is that\nsame work.\n\n  2. Basic Permissions.\n\n  All rights granted under this License are granted for the term of\ncopyright on the Program, and are irrevocable provided the stated\nconditions are met.  This License explicitly affirms your unlimited\npermission to run the unmodified Program.  The output from running a\ncovered work is covered by this License only if the output, given its\ncontent, constitutes a covered work.  This License acknowledges your\nrights of fair use or other equivalent, as provided by copyright law.\n\n  You may make, run and propagate covered works that you do not\nconvey, without conditions so long as your license otherwise remains\nin force.  You may convey covered works to others for the sole purpose\nof having them make modifications exclusively for you, or provide you\nwith facilities for running those works, provided that you comply with\nthe terms of this License in conveying all material for which you do\nnot control copyright.  Those thus making or running the covered works\nfor you must do so exclusively on your behalf, under your direction\nand control, on terms that prohibit them from making any copies of\nyour copyrighted material outside their relationship with you.\n\n  Conveying under any other circumstances is permitted solely under\nthe conditions stated below.  Sublicensing is not allowed; section 10\nmakes it unnecessary.\n\n  3. Protecting Users' Legal Rights From Anti-Circumvention Law.\n\n  No covered work shall be deemed part of an effective technological\nmeasure under any applicable law fulfilling obligations under article\n11 of the WIPO copyright treaty adopted on 20 December 1996, or\nsimilar laws prohibiting or restricting circumvention of such\nmeasures.\n\n  When you convey a covered work, you waive any legal power to forbid\ncircumvention of technological measures to the extent such circumvention\nis effected by exercising rights under this License with respect to\nthe covered work, and you disclaim any intention to limit operation or\nmodification of the work as a means of enforcing, against the work's\nusers, your or third parties' legal rights to forbid circumvention of\ntechnological measures.\n\n  4. Conveying Verbatim Copies.\n\n  You may convey verbatim copies of the Program's source code as you\nreceive it, in any medium, provided that you conspicuously and\nappropriately publish on each copy an appropriate copyright notice;\nkeep intact all notices stating that this License and any\nnon-permissive terms added in accord with section 7 apply to the code;\nkeep intact all notices of the absence of any warranty; and give all\nrecipients a copy of this License along with the Program.\n\n  You may charge any price or no price for each copy that you convey,\nand you may offer support or warranty protection for a fee.\n\n  5. Conveying Modified Source Versions.\n\n  You may convey a work based on the Program, or the modifications to\nproduce it from the Program, in the form of source code under the\nterms of section 4, provided that you also meet all of these conditions:\n\n    a) The work must carry prominent notices stating that you modified\n    it, and giving a relevant date.\n\n    b) The work must carry prominent notices stating that it is\n    released under this License and any conditions added under section\n    7.  This requirement modifies the requirement in section 4 to\n    &amp;quot;keep intact all notices&amp;quot;.\n\n    c) You must license the entire work, as a whole, under this\n    License to anyone who comes into possession of a copy.  This\n    License will therefore apply, along with any applicable section 7\n    additional terms, to the whole of the work, and all its parts,\n    regardless of how they are packaged.  This License gives no\n    permission to license the work in any other way, but it does not\n    invalidate such permission if you have separately received it.\n\n    d) If the work has interactive user interfaces, each must display\n    Appropriate Legal Notices; however, if the Program has interactive\n    interfaces that do not display Appropriate Legal Notices, your\n    work need not make them do so.\n\n  A compilation of a covered work with other separate and independent\nworks, which are not by their nature extensions of the covered work,\nand which are not combined with it such as to form a larger program,\nin or on a volume of a storage or distribution medium, is called an\n&amp;quot;aggregate&amp;quot; if the compilation and its resulting copyright are not\nused to limit the access or legal rights of the compilation's users\nbeyond what the individual works permit.  Inclusion of a covered work\nin an aggregate does not cause this License to apply to the other\nparts of the aggregate.\n\n  6. Conveying Non-Source Forms.\n\n  You may convey a covered work in object code form under the terms\nof sections 4 and 5, provided that you also convey the\nmachine-readable Corresponding Source under the terms of this License,\nin one of these ways:\n\n    a) Convey the object code in, or embodied in, a physical product\n    (including a physical distribution medium), accompanied by the\n    Corresponding Source fixed on a durable physical medium\n    customarily used for software interchange.\n\n    b) Convey the object code in, or embodied in, a physical product\n    (including a physical distribution medium), accompanied by a\n    written offer, valid for at least three years and valid for as\n    long as you offer spare parts or customer support for that product\n    model, to give anyone who possesses the object code either (1) a\n    copy of the Corresponding Source for all the software in the\n    product that is covered by this License, on a durable physical\n    medium customarily used for software interchange, for a price no\n    more than your reasonable cost of physically performing this\n    conveying of source, or (2) access to copy the\n    Corresponding Source from a network server at no charge.\n\n    c) Convey individual copies of the object code with a copy of the\n    written offer to provide the Corresponding Source.  This\n    alternative is allowed only occasionally and noncommercially, and\n    only if you received the object code with such an offer, in accord\n    with subsection 6b.\n\n    d) Convey the object code by offering access from a designated\n    place (gratis or for a charge), and offer equivalent access to the\n    Corresponding Source in the same way through the same place at no\n    further charge.  You need not require recipients to copy the\n    Corresponding Source along with the object code.  If the place to\n    copy the object code is a network server, the Corresponding Source\n    may be on a different server (operated by you or a third party)\n    that supports equivalent copying facilities, provided you maintain\n    clear directions next to the object code saying where to find the\n    Corresponding Source.  Regardless of what server hosts the\n    Corresponding Source, you remain obligated to ensure that it is\n    available for as long as needed to satisfy these requirements.\n\n    e) Convey the object code using peer-to-peer transmission, provided\n    you inform other peers where the object code and Corresponding\n    Source of the work are being offered to the general public at no\n    charge under subsection 6d.\n\n  A separable portion of the object code, whose source code is excluded\nfrom the Corresponding Source as a System Library, need not be\nincluded in conveying the object code work.\n\n  A &amp;quot;User Product&amp;quot; is either (1) a &amp;quot;consumer product&amp;quot;, which means any\ntangible personal property which is normally used for personal, family,\nor household purposes, or (2) anything designed or sold for incorporation\ninto a dwelling.  In determining whether a product is a consumer product,\ndoubtful cases shall be resolved in favor of coverage.  For a particular\nproduct received by a particular user, &amp;quot;normally used&amp;quot; refers to a\ntypical or common use of that class of product, regardless of the status\nof the particular user or of the way in which the particular user\nactually uses, or expects or is expected to use, the product.  A product\nis a consumer product regardless of whether the product has substantial\ncommercial, industrial or non-consumer uses, unless such uses represent\nthe only significant mode of use of the product.\n\n  &amp;quot;Installation Information&amp;quot; for a User Product means any methods,\nprocedures, authorization keys, or other information required to install\nand execute modified versions of a covered work in that User Product from\na modified version of its Corresponding Source.  The information must\nsuffice to ensure that the continued functioning of the modified object\ncode is in no case prevented or interfered with solely because\nmodification has been made.\n\n  If you convey an object code work under this section in, or with, or\nspecifically for use in, a User Product, and the conveying occurs as\npart of a transaction in which the right of possession and use of the\nUser Product is transferred to the recipient in perpetuity or for a\nfixed term (regardless of how the transaction is characterized), the\nCorresponding Source conveyed under this section must be accompanied\nby the Installation Information.  But this requirement does not apply\nif neither you nor any third party retains the ability to install\nmodified object code on the User Product (for example, the work has\nbeen installed in ROM).\n\n  The requirement to provide Installation Information does not include a\nrequirement to continue to provide support service, warranty, or updates\nfor a work that has been modified or installed by the recipient, or for\nthe User Product in which it has been modified or installed.  Access to a\nnetwork may be denied when the modification itself materially and\nadversely affects the operation of the network or violates the rules and\nprotocols for communication across the network.\n\n  Corresponding Source conveyed, and Installation Information provided,\nin accord with this section must be in a format that is publicly\ndocumented (and with an implementation available to the public in\nsource code form), and must require no special password or key for\nunpacking, reading or copying.\n\n  7. Additional Terms.\n\n  &amp;quot;Additional permissions&amp;quot; are terms that supplement the terms of this\nLicense by making exceptions from one or more of its conditions.\nAdditional permissions that are applicable to the entire Program shall\nbe treated as though they were included in this License, to the extent\nthat they are valid under applicable law.  If additional permissions\napply only to part of the Program, that part may be used separately\nunder those permissions, but the entire Program remains governed by\nthis License without regard to the additional permissions.\n\n  When you convey a copy of a covered work, you may at your option\nremove any additional permissions from that copy, or from any part of\nit.  (Additional permissions may be written to require their own\nremoval in certain cases when you modify the work.)  You may place\nadditional permissions on material, added by you to a covered work,\nfor which you have or can give appropriate copyright permission.\n\n  Notwithstanding any other provision of this License, for material you\nadd to a covered work, you may (if authorized by the copyright holders of\nthat material) supplement the terms of this License with terms:\n\n    a) Disclaiming warranty or limiting liability differently from the\n    terms of sections 15 and 16 of this License; or\n\n    b) Requiring preservation of specified reasonable legal notices or\n    author attributions in that material or in the Appropriate Legal\n    Notices displayed by works containing it; or\n\n    c) Prohibiting misrepresentation of the origin of that material, or\n    requiring that modified versions of such material be marked in\n    reasonable ways as different from the original version; or\n\n    d) Limiting the use for publicity purposes of names of licensors or\n    authors of the material; or\n\n    e) Declining to grant rights under trademark law for use of some\n    trade names, trademarks, or service marks; or\n\n    f) Requiring indemnification of licensors and authors of that\n    material by anyone who conveys the material (or modified versions of\n    it) with contractual assumptions of liability to the recipient, for\n    any liability that these contractual assumptions directly impose on\n    those licensors and authors.\n\n  All other non-permissive additional terms are considered &amp;quot;further\nrestrictions&amp;quot; within the meaning of section 10.  If the Program as you\nreceived it, or any part of it, contains a notice stating that it is\ngoverned by this License along with a term that is a further\nrestriction, you may remove that term.  If a license document contains\na further restriction but permits relicensing or conveying under this\nLicense, you may add to a covered work material governed by the terms\nof that license document, provided that the further restriction does\nnot survive such relicensing or conveying.\n\n  If you add terms to a covered work in accord with this section, you\nmust place, in the relevant source files, a statement of the\nadditional terms that apply to those files, or a notice indicating\nwhere to find the applicable terms.\n\n  Additional terms, permissive or non-permissive, may be stated in the\nform of a separately written license, or stated as exceptions;\nthe above requirements apply either way.\n\n  8. Termination.\n\n  You may not propagate or modify a covered work except as expressly\nprovided under this License.  Any attempt otherwise to propagate or\nmodify it is void, and will automatically terminate your rights under\nthis License (including any patent licenses granted under the third\nparagraph of section 11).\n\n  However, if you cease all violation of this License, then your\nlicense from a particular copyright holder is reinstated (a)\nprovisionally, unless and until the copyright holder explicitly and\nfinally terminates your license, and (b) permanently, if the copyright\nholder fails to notify you of the violation by some reasonable means\nprior to 60 days after the cessation.\n\n  Moreover, your license from a particular copyright holder is\nreinstated permanently if the copyright holder notifies you of the\nviolation by some reasonable means, this is the first time you have\nreceived notice of violation of this License (for any work) from that\ncopyright holder, and you cure the violation prior to 30 days after\nyour receipt of the notice.\n\n  Termination of your rights under this section does not terminate the\nlicenses of parties who have received copies or rights from you under\nthis License.  If your rights have been terminated and not permanently\nreinstated, you do not qualify to receive new licenses for the same\nmaterial under section 10.\n\n  9. Acceptance Not Required for Having Copies.\n\n  You are not required to accept this License in order to receive or\nrun a copy of the Program.  Ancillary propagation of a covered work\noccurring solely as a consequence of using peer-to-peer transmission\nto receive a copy likewise does not require acceptance.  However,\nnothing other than this License grants you permission to propagate or\nmodify any covered work.  These actions infringe copyright if you do\nnot accept this License.  Therefore, by modifying or propagating a\ncovered work, you indicate your acceptance of this License to do so.\n\n  10. Automatic Licensing of Downstream Recipients.\n\n  Each time you convey a covered work, the recipient automatically\nreceives a license from the original licensors, to run, modify and\npropagate that work, subject to this License.  You are not responsible\nfor enforcing compliance by third parties with this License.\n\n  An &amp;quot;entity transaction&amp;quot; is a transaction transferring control of an\norganization, or substantially all assets of one, or subdividing an\norganization, or merging organizations.  If propagation of a covered\nwork results from an entity transaction, each party to that\ntransaction who receives a copy of the work also receives whatever\nlicenses to the work the party's predecessor in interest had or could\ngive under the previous paragraph, plus a right to possession of the\nCorresponding Source of the work from the predecessor in interest, if\nthe predecessor has it or can get it with reasonable efforts.\n\n  You may not impose any further restrictions on the exercise of the\nrights granted or affirmed under this License.  For example, you may\nnot impose a license fee, royalty, or other charge for exercise of\nrights granted under this License, and you may not initiate litigation\n(including a cross-claim or counterclaim in a lawsuit) alleging that\nany patent claim is infringed by making, using, selling, offering for\nsale, or importing the Program or any portion of it.\n\n  11. Patents.\n\n  A &amp;quot;contributor&amp;quot; is a copyright holder who authorizes use under this\nLicense of the Program or a work on which the Program is based.  The\nwork thus licensed is called the contributor's &amp;quot;contributor version&amp;quot;.\n\n  A contributor's &amp;quot;essential patent claims&amp;quot; are all patent claims\nowned or controlled by the contributor, whether already acquired or\nhereafter acquired, that would be infringed by some manner, permitted\nby this License, of making, using, or selling its contributor version,\nbut do not include claims that would be infringed only as a\nconsequence of further modification of the contributor version.  For\npurposes of this definition, &amp;quot;control&amp;quot; includes the right to grant\npatent sublicenses in a manner consistent with the requirements of\nthis License.\n\n  Each contributor grants you a non-exclusive, worldwide, royalty-free\npatent license under the contributor's essential patent claims, to\nmake, use, sell, offer for sale, import and otherwise run, modify and\npropagate the contents of its contributor version.\n\n  In the following three paragraphs, a &amp;quot;patent license&amp;quot; is any express\nagreement or commitment, however denominated, not to enforce a patent\n(such as an express permission to practice a patent or covenant not to\nsue for patent infringement).  To &amp;quot;grant&amp;quot; such a patent license to a\nparty means to make such an agreement or commitment not to enforce a\npatent against the party.\n\n  If you convey a covered work, knowingly relying on a patent license,\nand the Corresponding Source of the work is not available for anyone\nto copy, free of charge and under the terms of this License, through a\npublicly available network server or other readily accessible means,\nthen you must either (1) cause the Corresponding Source to be so\navailable, or (2) arrange to deprive yourself of the benefit of the\npatent license for this particular work, or (3) arrange, in a manner\nconsistent with the requirements of this License, to extend the patent\nlicense to downstream recipients.  &amp;quot;Knowingly relying&amp;quot; means you have\nactual knowledge that, but for the patent license, your conveying the\ncovered work in a country, or your recipient's use of the covered work\nin a country, would infringe one or more identifiable patents in that\ncountry that you have reason to believe are valid.\n\n  If, pursuant to or in connection with a single transaction or\narrangement, you convey, or propagate by procuring conveyance of, a\ncovered work, and grant a patent license to some of the parties\nreceiving the covered work authorizing them to use, propagate, modify\nor convey a specific copy of the covered work, then the patent license\nyou grant is automatically extended to all recipients of the covered\nwork and works based on it.\n\n  A patent license is &amp;quot;discriminatory&amp;quot; if it does not include within\nthe scope of its coverage, prohibits the exercise of, or is\nconditioned on the non-exercise of one or more of the rights that are\nspecifically granted under this License.  You may not convey a covered\nwork if you are a party to an arrangement with a third party that is\nin the business of distributing software, under which you make payment\nto the third party based on the extent of your activity of conveying\nthe work, and under which the third party grants, to any of the\nparties who would receive the covered work from you, a discriminatory\npatent license (a) in connection with copies of the covered work\nconveyed by you (or copies made from those copies), or (b) primarily\nfor and in connection with specific products or compilations that\ncontain the covered work, unless you entered into that arrangement,\nor that patent license was granted, prior to 28 March 2007.\n\n  Nothing in this License shall be construed as excluding or limiting\nany implied license or other defenses to infringement that may\notherwise be available to you under applicable patent law.\n\n  12. No Surrender of Others' Freedom.\n\n  If conditions are imposed on you (whether by court order, agreement or\notherwise) that contradict the conditions of this License, they do not\nexcuse you from the conditions of this License.  If you cannot convey a\ncovered work so as to satisfy simultaneously your obligations under this\nLicense and any other pertinent obligations, then as a consequence you may\nnot convey it at all.  For example, if you agree to terms that obligate you\nto collect a royalty for further conveying from those to whom you convey\nthe Program, the only way you could satisfy both those terms and this\nLicense would be to refrain entirely from conveying the Program.\n\n  13. Use with the GNU Affero General Public License.\n\n  Notwithstanding any other provision of this License, you have\npermission to link or combine any covered work with a work licensed\nunder version 3 of the GNU Affero General Public License into a single\ncombined work, and to convey the resulting work.  The terms of this\nLicense will continue to apply to the part which is the covered work,\nbut the special requirements of the GNU Affero General Public License,\nsection 13, concerning interaction through a network will apply to the\ncombination as such.\n\n  14. Revised Versions of this License.\n\n  The Free Software Foundation may publish revised and/or new versions of\nthe GNU General Public License from time to time.  Such new versions will\nbe similar in spirit to the present version, but may differ in detail to\naddress new problems or concerns.\n\n  Each version is given a distinguishing version number.  If the\nProgram specifies that a certain numbered version of the GNU General\nPublic License &amp;quot;or any later version&amp;quot; applies to it, you have the\noption of following the terms and conditions either of that numbered\nversion or of any later version published by the Free Software\nFoundation.  If the Program does not specify a version number of the\nGNU General Public License, you may choose any version ever published\nby the Free Software Foundation.\n\n  If the Program specifies that a proxy can decide which future\nversions of the GNU General Public License can be used, that proxy's\npublic statement of acceptance of a version permanently authorizes you\nto choose that version for the Program.\n\n  Later license versions may give you additional or different\npermissions.  However, no additional obligations are imposed on any\nauthor or copyright holder as a result of your choosing to follow a\nlater version.\n\n  15. Disclaimer of Warranty.\n\n  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY\nAPPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT\nHOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM &amp;quot;AS IS&amp;quot; WITHOUT WARRANTY\nOF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,\nTHE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR\nPURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM\nIS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF\nALL NECESSARY SERVICING, REPAIR OR CORRECTION.\n\n  16. Limitation of Liability.\n\n  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING\nWILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS\nTHE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY\nGENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE\nUSE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF\nDATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD\nPARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),\nEVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF\nSUCH DAMAGES.\n\n  17. Interpretation of Sections 15 and 16.\n\n  If the disclaimer of warranty and limitation of liability provided\nabove cannot be given local legal effect according to their terms,\nreviewing courts shall apply local law that most closely approximates\nan absolute waiver of all civil liability in connection with the\nProgram, unless a warranty or assumption of liability accompanies a\ncopy of the Program in return for a fee.\n"}]
      GPL
      doi.rights_list = [{ "rights" => rights }]
      expect(doi.save).to be false
      expect(doi.errors.details).to eq(rights_list: [{ error: "Rights should not have a length of more than 2000 characters." }])
    end

    it "nil rights" do
      doi.rights_list = [{ "rights" => nil }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.rights_list).to eq([])
    end

    it "hash rightsIdentifier" do
      doi.rights_list = [{ "rightsIdentifier" => "CC-BY-4.0" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.rights_list).to eq([{ "rights" => "Creative Commons Attribution 4.0 International", "rightsUri" => "https://creativecommons.org/licenses/by/4.0/legalcode", "rightsIdentifier" => "cc-by-4.0", "rightsIdentifierScheme" => "SPDX", "schemeUri" => "https://spdx.org/licenses/" }])
    end

    it "hash rightsUri" do
      doi.rights_list = [{ "rightsURI" => "https://creativecommons.org/licenses/by/4.0/legalcode" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.rights_list).to eq([{ "rights" => "Creative Commons Attribution 4.0 International", "rightsUri" => "https://creativecommons.org/licenses/by/4.0/legalcode", "rightsIdentifier" => "cc-by-4.0", "rightsIdentifierScheme" => "SPDX", "schemeUri" => "https://spdx.org/licenses/" }])
    end

    it "hash rightsUri http" do
      doi.rights_list = [{ "rightsURI" => "http://creativecommons.org/licenses/by/4.0/" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.rights_list).to eq([{ "rights" => "Creative Commons Attribution 4.0 International", "rightsUri" => "https://creativecommons.org/licenses/by/4.0/legalcode", "rightsIdentifier" => "cc-by-4.0", "rightsIdentifierScheme" => "SPDX", "schemeUri" => "https://spdx.org/licenses/" }])
    end
  end

  describe "subjects" do
    let(:doi) { build(:doi) }

    it "hash" do
      doi.subjects = [{ "subject" => "Tree" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.subjects).to eq([{ "subject" => "Tree" }])
    end

    it "string" do
      doi.subjects = ["Tree"]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.subjects).to eq([{ "subject" => "Tree" }])
    end
  end

  describe "dates" do
    let(:doi) { build(:doi) }

    it "full date" do
      doi.dates = [{ "date" => "2019-08-01" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "year-month" do
      doi.dates = [{ "date" => "2019-08" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "year" do
      doi.dates = [{ "date" => "2019" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "date range" do
      doi.dates = [{ "date" => "2019-07-31/2019-08-01" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "date range years" do
      doi.dates = [{ "date" => "2018/2019" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "datetime" do
      doi.dates = [{ "date" => "2019-08-01T20:28:15" }]
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
    end

    it "string" do
      doi.dates = ["2019-08-01"]
      expect(doi.save).to be false
      expect(doi.errors.details).to eq(dates: [{ error: "Date 2019-08-01 should be an object instead of a string." }])
    end
  end

  describe "identifiers" do
    it "publisher id" do
      subject = build(:doi, identifiers: [{
                        "identifierType": "publisher ID",
                        "identifier": "pk-1234",
                      }])
      expect(subject).to be_valid
      expect(subject.identifiers).to eq([{ "identifier" => "pk-1234", "identifierType" => "publisher ID" }])
    end

    it "string" do
      subject = build(:doi, identifiers: ["pk-1234"])
      expect(subject).to_not be_valid
      expect(subject.errors.messages).to eq(identifiers: ["Identifier 'pk-1234' should be an object instead of a string."])
    end

    it "doi" do
      subject = build(:doi, identifiers: [{
                        "identifierType": "DOI",
                        "identifier": "10.4224/abc",
                      }])
      expect(subject).to be_valid
      expect(subject.errors.messages).to be_empty
      expect(subject.identifiers).to be_empty
    end
  end

  describe "types" do
    let(:doi) { build(:doi) }

    it "string" do
      doi.types = "Dataset"
      expect(doi.save).to be false
      expect(doi.errors.details).to eq(types: [{ error: "Types 'Dataset' should be an object instead of a string." }])
    end

    it "only resource_type_general" do
      doi.types = { "resourceTypeGeneral" => "Dataset" }
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.types).to eq("bibtex" => "misc", "citeproc" => "dataset", "resourceTypeGeneral" => "Dataset", "ris" => "DATA", "schemaOrg" => "Dataset")
    end

    it "resource_type and resource_type_general" do
      doi.types = { "resourceTypeGeneral" => "Dataset", "resourceType" => "EEG data" }
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.types).to eq("bibtex" => "misc", "citeproc" => "dataset", "resourceTypeGeneral" => "Dataset", "resourceType" => "EEG data", "ris" => "DATA", "schemaOrg" => "Dataset")
    end

    it "resource_type_general and different schema_org" do
      doi.types = { "resourceTypeGeneral" => "Dataset", "schemaOrg" => "JournalArticle" }
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.types).to eq("bibtex" => "misc", "citeproc" => "dataset", "resourceTypeGeneral" => "Dataset", "ris" => "DATA", "schemaOrg" => "JournalArticle")
    end

    it "resource_type_general and different ris" do
      doi.types = { "resourceTypeGeneral" => "Dataset", "ris" => "GEN" }
      expect(doi.save).to be true
      expect(doi.errors.details).to be_empty
      expect(doi.types).to eq("bibtex" => "misc", "citeproc" => "dataset", "resourceTypeGeneral" => "Dataset", "ris" => "GEN", "schemaOrg" => "Dataset")
    end
  end

  describe "related_items" do
    it "is complete" do
      related_item = {
        "relatedItemType" => "Journal",
        "relationType" => "IsPublishedIn",
        "relatedItemIdentifier" =>
        {
          "relatedItemIdentifier" => "10.5072/john-smiths-1234",
          "relatedItemIdentifierType" => "DOI",
          "relatedMetadataScheme" => "citeproc+json",
          "schemeURI" => "https://github.com/citation-style-language/schema/raw/master/csl-data.json",
          "schemeType" => "URL"
        },
        "creators" =>
        [
          { "nameType" => "Personal", "name" => "Smith, John", "givenName" => "John", "familyName" => "Smith" }
        ],
        "titles" =>
        [
          { "title" => "Understanding the fictional John Smith" },
          { "title" => "A detailed look", "titleType" => "Subtitle" }
        ],
        "volume" => "776",
        "issue" => "1",
        "number" => "1",
        "numberType" => "Chapter",
        "firstPage" => "50",
        "lastPage" => "60",
        "publisher" => "Example Inc",
        "publicationYear" => "1776",
        "edition" => "1",
        "contributors" =>
        [
          { "name" => "Hallett, Richard", "givenName" => "Richard", "familyName" => "Hallett", "contributorType" => "ProjectLeader" }
        ]
      }

      doi = build(:doi, related_items: [related_item])
      expect(doi.save).to be true
      expect(doi).to be_valid
      expect(doi.errors.details).to be_empty
      expect(doi.related_items).to eq([related_item])
    end
  end

  describe "organization_id" do
    it "from creators" do
      subject = build(
        :doi,
        publisher: {
          "name": "DataCite"
        },
        creators: [
          {
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://ror.org/013meh555",
                "nameIdentifierScheme" => "ROR",
              },
            ],
            "nameType" => "Personal",
          },
        ]
      )
      expect(subject).to be_valid
      expect(subject.organization_id).to eq(
        [
          "ror.org/013meh555",
        ]
      )
    end

    it "from contributors(sponsor)" do
      subject = build(
        :doi,
        publisher: {
          "name": "DataCite"
        },
        creators: [],
        contributors: [
          {
            "contributorType" => "Sponsor",
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://ror.org/013meh444",
                "nameIdentifierScheme" => "ROR",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Cambridge",
                "affiliationIdentifier" => "https://ror.org/013meh723",
                "affiliationIdentifierScheme" => "ROR",
              },
            ],
          },
        ]
      )
      expect(subject).to be_valid
      expect(subject.organization_id).to eq(
        [
          "ror.org/013meh444",
        ]
      )
    end

    it "will be populated with contributors(non-sponsor)" do
      subject = build(
        :doi,
        publisher: {
          "name": "DataCite"
        },
        creators: [],
        contributors: [
          {
            "contributorType" => "ProjectLeader",
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://ror.org/013meh333",
                "nameIdentifierScheme" => "ROR",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Cambridge",
                "affiliationIdentifier" => "https://ror.org/013meh723",
                "affiliationIdentifierScheme" => "ROR",
              },
            ],
          },
        ]
      )
      expect(subject).to be_valid
      expect(subject.organization_id).to eq(
        [
          "ror.org/013meh333",
        ]
      )
    end

    it "from creators_and_contributors(sponsored)" do
      subject = build(
        :doi,
        publisher: {
          "name": "DataCite"
        },
        creators: [
          {
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://ror.org/013meh333",
                "nameIdentifierScheme" => "ROR",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Cambridge",
                "affiliationIdentifier" => "https://ror.org/013meh722",
                "affiliationIdentifierScheme" => "ROR",
              },
            ],
          },
        ],
        contributors: [
          {
            "contributorType" => "Sponsor",
            "familyName" => "Bob",
            "givenName" => "Jones",
            "name" => "Jones, Bob",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://ror.org/013meh111",
                "nameIdentifierScheme" => "ROR",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Examples",
                "affiliationIdentifier" => "https://ror.org/013meh8888",
                "affiliationIdentifierScheme" => "ROR",
              },
            ],
          },
        ]
      )
      expect(subject).to be_valid
      expect(subject.organization_id).to eq(
        [
          "ror.org/013meh333",
          "ror.org/013meh111",
        ]
      )
    end

    it "from publisher" do
      subject = build(
        :doi,
        publisher: {
          "name": "DataCite",
          "publisherIdentifier": "https://ror.org/013meh444",
          "publisherIdentifierScheme": "ROR"
        },
        creators: [],
        contributors: []
      )
      expect(subject).to be_valid
      expect(subject.organization_id).to eq(
        [
          "ror.org/013meh444",
        ]
      )
    end
  end

  describe "fair_organization_id" do
    it "will be empty from contributors(non-sponsor)" do
      subject = build(
        :doi,
        creators: [],
        contributors: [
          {
            "contributorType" => "ProjectLeader",
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://ror.org/013meh333",
                "nameIdentifierScheme" => "ROR",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Cambridge",
                "affiliationIdentifier" => "https://ror.org/013meh723",
                "affiliationIdentifierScheme" => "ROR",
              },
            ],
          },
        ]
      )
      expect(subject).to be_valid
      expect(subject.fair_organization_id).to eq(
        [
        ]
      )
    end

    it "from creators_and_contributors(sponsored)" do
      subject = build(
        :doi,
        creators: [
          {
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://ror.org/013meh333",
                "nameIdentifierScheme" => "ROR",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Cambridge",
                "affiliationIdentifier" => "https://ror.org/013meh722",
                "affiliationIdentifierScheme" => "ROR",
              },
            ],
          },
        ],
        contributors: [
          {
            "contributorType" => "Sponsor",
            "familyName" => "Bob",
            "givenName" => "Jones",
            "name" => "Jones, Bob",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://ror.org/013meh111",
                "nameIdentifierScheme" => "ROR",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Examples",
                "affiliationIdentifier" => "https://ror.org/013meh8888",
                "affiliationIdentifierScheme" => "ROR",
              },
            ],
          },
        ]
      )
      expect(subject).to be_valid
      expect(subject.fair_organization_id).to eq(
        [
          "ror.org/013meh333",
          "ror.org/013meh111",
        ]
      )
    end
  end

  describe "affiliation_id" do
    it "from creators" do
      subject = build(
        :doi,
        creators: [
          {
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Cambridge",
                "affiliationIdentifier" => "https://ror.org/013meh722",
                "affiliationIdentifierScheme" => "ROR",
              },
            ],
          },
        ]
      )
      expect(subject).to be_valid
      expect(subject.affiliation_id).to eq(
        [
          "ror.org/013meh722",
        ]
      )
    end

    it "from contributors(sponsor)" do
      subject = build(
        :doi,
        creators: [],
        contributors: [
          {
            "contributorType" => "Sponsor",
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Cambridge",
                "affiliationIdentifier" => "https://ror.org/013meh723",
                "affiliationIdentifierScheme" => "ROR",
              },
            ],
          },
        ]
      )
      expect(subject).to be_valid
      expect(subject.affiliation_id).to eq(
        [
          "ror.org/013meh723",
        ]
      )
    end

    it "will be empty from contributors(non-sponsor)" do
      subject = build(
        :doi,
        creators: [],
        contributors: [
          {
            "contributorType" => "ProjectLeader",
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Cambridge",
                "affiliationIdentifier" => "https://ror.org/013meh723",
                "affiliationIdentifierScheme" => "ROR",
              },
            ],
          },
        ]
      )
      expect(subject).to be_valid
      expect(subject.affiliation_id).to eq(
        [
          "ror.org/013meh723",
        ]
      )
    end

    it "from creators_and_contributors(sponsored)" do
      subject = build(
        :doi,
        creators: [
          {
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Cambridge",
                "affiliationIdentifier" => "https://ror.org/013meh722",
                "affiliationIdentifierScheme" => "ROR",
              },
           ],
          },
        ],
        contributors: [
          {
            "contributorType" => "Sponsor",
            "familyName" => "Bob",
            "givenName" => "Jones",
            "name" => "Jones, Bob",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-0000",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Examples",
                "affiliationIdentifier" => "https://ror.org/013meh8888",
                "affiliationIdentifierScheme" => "ROR",
              },
           ],
          },
        ]
      )
      expect(subject).to be_valid
      expect(subject.affiliation_id).to eq(
        [
          "ror.org/013meh722",
          "ror.org/013meh8888",
        ]
      )
    end
  end

  describe "fair_affiliation_id" do
    it "will be empty from contributors(non-sponsor)" do
      subject = build(
        :doi,
        creators: [],
        contributors: [
          {
            "contributorType" => "ProjectLeader",
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Cambridge",
                "affiliationIdentifier" => "https://ror.org/013meh723",
                "affiliationIdentifierScheme" => "ROR",
              },
            ],
          },
        ]
      )
      expect(subject).to be_valid
      expect(subject.fair_affiliation_id).to eq(
        [
        ]
      )
    end

    it "from creators_and_contributors(sponsored)" do
      subject = build(
        :doi,
        creators: [
          {
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Cambridge",
                "affiliationIdentifier" => "https://ror.org/013meh722",
                "affiliationIdentifierScheme" => "ROR",
              },
           ],
          },
        ],
        contributors: [
          {
            "contributorType" => "Sponsor",
            "familyName" => "Bob",
            "givenName" => "Jones",
            "name" => "Jones, Bob",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-0000",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Examples",
                "affiliationIdentifier" => "https://ror.org/013meh8888",
                "affiliationIdentifierScheme" => "ROR",
              },
           ],
          },
        ]
      )
      expect(subject).to be_valid
      expect(subject.fair_affiliation_id).to eq(
        [
          "ror.org/013meh722",
          "ror.org/013meh8888",
        ]
      )
    end
  end

  describe "person_ids" do
    it "from creators and contributors" do
      subject = build(
        :doi,
        creators: [
          {
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Cambridge",
                "affiliationIdentifier" => "https://ror.org/013meh722",
                "affiliationIdentifierScheme" => "ROR",
              },
           ],
          },
        ],
        contributors: [
          {
            "contributorType" => "Sponsor",
            "familyName" => "Bob",
            "givenName" => "Jones",
            "name" => "Jones, Bob",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-3484-0000",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Examples",
                "affiliationIdentifier" => "https://ror.org/013meh8888",
                "affiliationIdentifierScheme" => "ROR",
              },
           ],
          },
          {
            "contributorType" => "Translator",
            "familyName" => "Doe",
            "givenName" => "Jane",
            "name" => "Doe, Jane",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-0800-1234",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "Example Translation Services",
                "affiliationIdentifier" => "https://ror.org/013meh9876",
                "affiliationIdentifierScheme" => "ROR",
              },
           ],
          },
        ]
      )
      expect(subject).to be_valid
      expect(subject.person_id).to eq(
        [
          "https://orcid.org/0000-0003-3484-6875",
          "https://orcid.org/0000-0003-3484-0000",
          "https://orcid.org/0000-0003-0800-1234",  # Contributor: Jane Doe (Translator)
        ]
      )
    end
  end

  describe "related_identifiers" do
    it "has part" do
      subject = build(:doi, related_identifiers: [
        {
          "relatedIdentifier": "10.5061/dryad.8515/1",
          "relatedIdentifierType": "DOI",
          "relationType": "HasPart",
        }
      ])
      expect(subject).to be_valid
      expect(subject.related_identifiers).to eq([
        {
          "relatedIdentifier" => "10.5061/dryad.8515/1",
          "relatedIdentifierType" => "DOI",
          "relationType" => "HasPart"
        }
      ])
    end

    it "has a related datamanagment plan" do
      subject = build(:doi, related_identifiers: [
        {
          "relatedIdentifier": "10.5061/dryad.8515/1",
          "relatedIdentifierType": "DOI",
          "relationType": "HasPart",
          "resourceTypeGeneral": "OutputManagementPlan",
        }
      ])
      expect(subject).to be_valid
      expect(subject.related_dmp_ids).to eq([
         "10.5061/dryad.8515/1",
      ])
    end

    it "has a organization_id thorugh a related datamanagment plan" do
      related_dmp = create(
        :doi,
        publisher: {
          "name": "DataCite",
          "publisherIdentifier": "https://ror.org/013meh555",
          "publisherIdentifierScheme": "ROR"
        },
        creators: [
          {
            "familyName" => "Garza",
            "givenName" => "Kristian",
            "name" => "Garza, Kristian",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://ror.org/013meh333",
                "nameIdentifierScheme" => "ROR",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Cambridge",
                "affiliationIdentifier" => "https://ror.org/013meh722",
                "affiliationIdentifierScheme" => "ROR",
              },
            ],
          },
        ],
        contributors: [
          {
            "contributorType" => "Sponsor",
            "familyName" => "Bob",
            "givenName" => "Jones",
            "name" => "Jones, Bob",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://ror.org/013meh111",
                "nameIdentifierScheme" => "ROR",
              },
            ],
            "nameType" => "Personal",
            "affiliation" => [
              {
                "name" => "University of Examples",
                "affiliationIdentifier" => "https://ror.org/013meh8888",
                "affiliationIdentifierScheme" => "ROR",
              },
            ],
          },
        ]
      )

      subject = build(:doi, related_identifiers: [
        {
          "relatedIdentifier": related_dmp.doi,
          "relatedIdentifierType": "DOI",
          "relationType": "HasPart",
          "resourceTypeGeneral": "OutputManagementPlan",
        }
      ])
      expect(subject).to be_valid
      expect(subject.related_dmp_ids).to eq([
        related_dmp.doi,
      ])
      expect(subject.related_dmp_organization_and_affiliation_id).to eq(
        [
          "ror.org/013meh333",
          "ror.org/013meh111",
          "ror.org/013meh555",
          "ror.org/013meh722",
          "ror.org/013meh8888",
        ]
      )
    end
  end

  describe "metadata" do
    subject { create(:doi) }

    it "valid" do
      expect(subject.valid?).to be true
    end

    it "titles" do
      expect(subject.titles).to eq([{ "title" => "Data from: A new malaria agent in African hominids." }])
    end

    it "creators" do
      expect(subject.creators.length).to eq(8)
      expect(subject.creators.first).to eq("familyName" => "Ollomo", "givenName" => "Benjamin", "name" => "Ollomo, Benjamin", "nameType" => "Personal")
    end

    it "dates" do
      expect(subject.get_date(subject.dates, "Issued")).to eq("2011")
    end

    it "publication_year" do
      expect(subject.publication_year).to eq(2011)
    end

    it "publisher" do
      expect(subject.publisher).to eq({
        "name" => "Dryad Digital Repository",
        "publisherIdentifier" => "https://ror.org/00x6h5n95",
        "publisherIdentifierScheme" => "ROR",
        "schemeUri" => "https://ror.org/",
        "lang" => "en"
      })
    end

    it "schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-4")
    end

    it "xml" do
      doc = Nokogiri::XML(subject.xml, nil, "UTF-8", &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "metadata" do
      doc = Nokogiri::XML(subject.metadata.first.xml, nil, "UTF-8", &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "namespace" do
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-4")
    end
  end

  describe "change metadata" do
    let(:xml) { File.read(file_fixture("datacite_f1000.xml")) }
    let(:title) { "Triose Phosphate Isomerase Deficiency Is Caused by Altered Dimerization–Not Catalytic Inactivity–of the Mutant Enzymes" }
    let(:creators) { [{ "name" => "Ollomi, Benjamin" }, { "name" => "Duran, Patrick" }] }
    let(:publisher) { "Zenodo" }
    let(:publication_year) { 2011 }
    let(:types) { { "resourceTypeGeneral" => "Software", "resourceType" => "BlogPosting", "schemaOrg" => "BlogPosting" } }
    let(:description) { "Eating your own dog food is a slang term to describe that an organization should itself use the products and services it provides. For DataCite this means that we should use DOIs with appropriate metadata and strategies for long-term preservation for..." }

    subject do
      create(:doi,
             xml: xml,
             titles: [{ "title" => title }],
             creators: creators,
             publisher: publisher,
             publication_year: publication_year,
             types: types,
             descriptions: [{ "description" => description }],
             event: "publish")
    end

    it "titles" do
      expect(subject.titles).to eq([{ "title" => title }])

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("titles", "title")).to eq(title)
    end

    it "creators" do
      expect(subject.creators).to eq(creators)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("creators", "creator")).to eq([{ "creatorName" => "Ollomi, Benjamin" }, { "creatorName" => "Duran, Patrick" }])
    end

    it "publisher" do
      expect(subject.publisher).to eq({ "name" => publisher })

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("publisher")).to eq(publisher)
    end

    it "publication_year" do
      expect(subject.publication_year).to eq(2011)

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("publicationYear")).to eq("2011")
    end

    it "resource_type" do
      expect(subject.types["resourceType"]).to eq("BlogPosting")

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("resourceType")).to eq("resourceTypeGeneral" => "Software", "__content__" => "BlogPosting")
    end

    it "resource_type_general" do
      expect(subject.types["resourceTypeGeneral"]).to eq("Software")

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("resourceType")).to eq("resourceTypeGeneral" => "Software", "__content__" => "BlogPosting")
    end

    it "descriptions" do
      expect(subject.descriptions).to eq([{ "description" => description }])

      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("descriptions", "description")).to eq("__content__" => "Eating your own dog food is a slang term to describe that an organization should itself use the products and services it provides. For DataCite this means that we should use DOIs with appropriate metadata and strategies for long-term preservation for...", "descriptionType" => "Abstract")
    end

    it "schema_version" do
      expect(subject.schema_version).to eq("http://datacite.org/schema/kernel-4")
      xml = Maremma.from_xml(subject.xml).fetch("resource", {})
      expect(xml.dig("xmlns")).to eq("http://datacite.org/schema/kernel-4")
      expect(subject.metadata.first.namespace).to eq("http://datacite.org/schema/kernel-4")
    end
  end

  describe "to_jsonapi" do
    let(:provider) { create(:provider, symbol: "ADMIN") }
    let(:client) { create(:client, provider: provider) }
    let(:doi) { create(:doi, client: client) }

    it "works" do
      params = doi.to_jsonapi
      expect(params.dig("id")).to eq(doi.doi)
      expect(params.dig("attributes", "state")).to eq("draft")
      expect(params.dig("attributes", "created")).to eq(doi.created)
      expect(params.dig("attributes", "updated")).to eq(doi.updated)
    end
  end

  describe "content negotiation" do
    subject { create(:doi, doi: "10.5438/4k3m-nyvg", event: "publish") }

    it "validates against schema" do
      expect(subject.valid?).to be true
    end

    it "generates datacite_xml" do
      doc = Nokogiri::XML(subject.xml, nil, "UTF-8", &:noblanks)
      expect(doc.at_css("identifier").content).to eq(subject.doi)
    end

    it "generates bibtex" do
      bibtex = BibTeX.parse(subject.bibtex).to_a(quotes: "").first
      expect(bibtex[:bibtex_type].to_s).to eq("misc")
      expect(bibtex[:title].to_s).to eq("Data from: A new malaria agent in African hominids.")
    end

    it "generates ris" do
      ris = subject.ris.split("\r\n")
      expect(ris[0]).to eq("TY  - DATA")
      expect(ris[1]).to eq("T1  - Data from: A new malaria agent in African hominids.")
    end

    it "generates schema_org" do
      json = JSON.parse(subject.schema_org)
      expect(json["@type"]).to eq("Dataset")
      expect(json["name"]).to eq("Data from: A new malaria agent in African hominids.")
    end

    it "generates datacite_json" do
      json = JSON.parse(subject.datacite_json)
      expect(json["doi"]).to eq("10.5438/4K3M-NYVG")
      expect(json["titles"]).to eq([{ "title" => "Data from: A new malaria agent in African hominids." }])
    end

    it "generates codemeta" do
      json = JSON.parse(subject.codemeta)
      expect(json["@type"]).to eq("Dataset")
      expect(json["name"]).to eq("Data from: A new malaria agent in African hominids.")
    end

    it "generates jats" do
      jats = Maremma.from_xml(subject.jats).fetch("element_citation", {})
      expect(jats.dig("publication_type")).to eq("data")
      expect(jats.dig("data_title")).to eq("Data from: A new malaria agent in African hominids.")
    end
  end

  describe "transfer", elasticsearch: true, prefix_pool_size: 3 do
    let(:provider) { create(:provider) }
    let(:client) { create(:client, provider: provider) }
    let(:target) { create(:client, provider: provider, symbol: provider.symbol + ".TARGET", name: "Target Client") }
    let!(:dois) { create_list(:doi, 5, client: client, aasm_state: "findable") }

    before do
      Doi.import
      sleep 2
    end

    it "transfer all dois" do
      response = Doi.transfer(client_id: client.symbol.downcase, client_target_id: target.symbol.downcase, size: 3)
      expect(response).to eq(5)
    end
  end


  describe "convert_affiliations" do
    let(:doi) { create(:doi) }

    context "affiliation nil" do
      let(:creators) do
        [{
          "name": "Ausmees, K.",
          "nameType": "Personal",
          "givenName": "K.",
          "familyName": "Ausmees",
          "affiliation": nil,
        }]
      end
      let(:doi) { create(:doi, creators: creators, contributors: []) }

      it "convert" do
        expect(Doi.convert_affiliation_by_id(id: doi.id)).to eq(1)
      end
    end

    context "affiliation empty array" do
      let(:creators) do
        [{
          "name": "Ausmees, K.",
          "nameType": "Personal",
          "givenName": "K.",
          "familyName": "Ausmees",
          "affiliation": [],
        }]
      end
      let(:doi) { create(:doi, creators: creators, contributors: []) }

      it "convert" do
        expect(Doi.convert_affiliation_by_id(id: doi.id)).to eq(0)
      end
    end

    context "affiliation array of hashes" do
      let(:creators) do
        [{
          "name": "Ausmees, K.",
          "nameType": "Personal",
          "givenName": "K.",
          "familyName": "Ausmees",
          "affiliation": [{ "name": "Department of Microbiology; Tartu University; Tartu Estonia" }],
        }]
      end
      let(:doi) { create(:doi, creators: creators, contributors: []) }

      it "convert" do
        expect(Doi.convert_affiliation_by_id(id: doi.id)).to eq(0)
      end
    end

    context "affiliation hash" do
      let(:creators) do
        [{
          "name": "Ausmees, K.",
          "nameType": "Personal",
          "givenName": "K.",
          "familyName": "Ausmees",
          "affiliation": { "name": "Department of Microbiology; Tartu University; Tartu Estonia" },
        }]
      end
      let(:doi) { create(:doi, creators: creators, contributors: []) }

      it "convert" do
        expect(Doi.convert_affiliation_by_id(id: doi.id)).to eq(1)
      end
    end

    context "affiliation array of strings" do
      let(:creators) do
        [{
          "name": "Ausmees, K.",
          "nameType": "Personal",
          "givenName": "K.",
          "familyName": "Ausmees",
          "affiliation": ["Andrology Centre; Tartu University Hospital; Tartu Estonia", "Department of Surgery; Tartu University; Tartu Estonia"],
        }]
      end
      let(:doi) { create(:doi, creators: creators, contributors: []) }

      it "convert" do
        expect(Doi.convert_affiliation_by_id(id: doi.id)).to eq(1)
      end
    end

    context "affiliation string" do
      let(:creators) do
        [{
          "name": "Ausmees, K.",
          "nameType": "Personal",
          "givenName": "K.",
          "familyName": "Ausmees",
          "affiliation": "Andrology Centre; Tartu University Hospital; Tartu Estonia",
        }]
      end
      let(:doi) { create(:doi, creators: creators, contributors: []) }

      it "convert" do
        expect(Doi.convert_affiliation_by_id(id: doi.id)).to eq(1)
      end
    end
  end

  describe "convert_containers" do
    let(:doi) { create(:doi) }

    context "container nil" do
      let(:container) { nil }
      let(:doi) { create(:doi, container: container) }

      it "convert" do
        expect(Doi.convert_container_by_id(id: doi.id)).to eq(0)
      end
    end

    context "container hash with strings" do
      let(:container) do
        {
          "type": "Journal",
          "issue": "6",
          "title": "Journal of Crustacean Biology",
          "volume": "32",
          "lastPage": "961",
          "firstPage": "949",
          "identifier": "1937-240X",
          "identifierType": "ISSN",
        }
      end
      let(:doi) { create(:doi, container: container) }

      it "not convert" do
        expect(Doi.convert_container_by_id(id: doi.id)).to eq(0)
      end
    end

    context "container hash with hashes" do
      let(:container) do
        {
          "type": "Journal",
          "issue": { "xmlns:foaf": "http://xmlns.com/foaf/0.1/", "xmlns:rdfs": "http://www.w3.org/2000/01/rdf-schema#", "__content__": "6" },
          "title": { "xmlns:foaf": "http://xmlns.com/foaf/0.1/", "xmlns:rdfs": "http://www.w3.org/2000/01/rdf-schema#", "__content__": "Journal of Crustacean Biology" },
          "volume": { "xmlns:foaf": "http://xmlns.com/foaf/0.1/", "xmlns:rdfs": "http://www.w3.org/2000/01/rdf-schema#", "__content__": "32" },
          "lastPage": "961",
          "firstPage": "949",
          "identifier": "1937-240X",
          "identifierType": "ISSN",
        }
      end
      let(:doi) { create(:doi, container: container, related_items: nil) }

      it "convert" do
        expect(Doi.convert_container_by_id(id: doi.id)).to eq(1)
      end
    end
  end

  describe "repair landing page" do
    let(:provider) { create(:provider, symbol: "ADMIN") }
    let(:client) { create(:client, provider: provider) }
    let(:time_now) { Time.zone.now.iso8601 }

    let(:landing_page) do
      {
        "checked" => time_now,
        "status" => 200,
        "url" => "http://example.com",
        "contentType" => "text/html",
        "error" => nil,
        "redirectCount" => 0,
        "redirectUrls" => ["http://example.com", "https://example.com"],
        "downloadLatency" => 200,
        "hasSchemaOrg" => true,
        "schemaOrgId" => [
          {
            "@type": "PropertyValue",
            "propertyID": "URL",
            "value": "http://dx.doi.org/10.4225/06/565BCE14467D0",
          },
        ],
        "dcIdentifier" => nil,
        "citationDoi" => nil,
        "bodyHasPid" => true,
      }
    end

    let(:doi) do
      create(:doi, client: client, landing_page: landing_page)
    end

    before { doi.save }

    let(:fixed_landing_page) do
      {
        "checked" => time_now,
        "status" => 200,
        "url" => "http://example.com",
        "contentType" => "text/html",
        "error" => nil,
        "redirectCount" => 0,
        "redirectUrls" => ["http://example.com", "https://example.com"],
        "downloadLatency" => 200,
        "hasSchemaOrg" => true,
        "schemaOrgId" => "http://dx.doi.org/10.4225/06/565BCE14467D0",
        "dcIdentifier" => nil,
        "citationDoi" => nil,
        "bodyHasPid" => true,
      }
    end

    it "repairs data" do
      Doi.repair_landing_page(id: doi.id)

      changed_doi = Doi.where(id: doi.id).first

      expect(changed_doi.landing_page).to eq(fixed_landing_page)
    end
  end

  describe "migrates landing page" do
    let(:provider) { create(:provider, symbol: "ADMIN") }
    let(:client) { create(:client, provider: provider) }

    let(:last_landing_page_status_result) do
      {
        "error" => nil,
        "redirect-count" => 0,
        "redirect-urls" => ["http://example.com", "https://example.com"],
        "download-latency" => 200.323232,
        "has-schema-org" => true,
        "schema-org-id" => "10.14454/10703",
        "dc-identifier" => nil,
        "citation-doi" => nil,
        "body-has-pid" => true,
      }
    end

    let(:time_now) { Time.zone.now.iso8601 }

    let(:doi) do
      create(:doi,
             client: client,
             last_landing_page_status: 200,
             last_landing_page_status_check: time_now,
             last_landing_page_content_type: "text/html",
             last_landing_page: "http://example.com",
             last_landing_page_status_result: last_landing_page_status_result)
    end

    let(:landing_page) do
      {
        "checked" => time_now,
        "status" => 200,
        "url" => "http://example.com",
        "contentType" => "text/html",
        "error" => nil,
        "redirectCount" => 0,
        "redirectUrls" => ["http://example.com", "https://example.com"],
        "downloadLatency" => 200,
        "hasSchemaOrg" => true,
        "schemaOrgId" => "10.14454/10703",
        "dcIdentifier" => nil,
        "citationDoi" => nil,
        "bodyHasPid" => true,
      }
    end

    before { doi.save }

    it "migrates and corrects data" do
      Doi.migrate_landing_page

      changed_doi = Doi.find(doi.id)

      expect(changed_doi.landing_page).to eq(landing_page)
    end
  end

  describe "stats_query", elasticsearch: true, prefix_pool_size: 3 do
    subject { Doi }

    before do
      allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 4, 8))
    end

    let(:consortium) { create(:provider, role_name: "ROLE_CONSORTIUM", symbol: "DC") }
    let(:provider) { create(:provider, consortium: consortium, role_name: "ROLE_CONSORTIUM_ORGANIZATION", symbol: "DATACITE") }
    let(:client) { create(:client, provider: provider, symbol: "DATACITE.TEST") }
    let!(:dois) { create_list(:doi, 3, client: client, aasm_state: "findable") }
    let!(:doi) { create(:doi) }

    it "counts all dois" do
      Doi.import
      sleep 2

      response = subject.stats_query
      expect(response.results.total).to eq(4)
      expect(response.aggregations.created.buckets).to eq([{ "doc_count" => 4, "key" => 1420070400000, "key_as_string" => "2015" }])
    end

    it "counts all consortia dois" do
      Doi.import
      sleep 2

      response = subject.stats_query(consortium_id: "dc")
      expect(response.results.total).to eq(3)
      expect(response.aggregations.created.buckets).to eq([{ "doc_count" => 3, "key" => 1420070400000, "key_as_string" => "2015" }])
    end

    it "counts all consortia dois no dois" do
      Doi.import
      sleep 2

      response = subject.stats_query(consortium_id: "abc")
      expect(response.results.total).to eq(0)
      expect(response.aggregations.created.buckets).to eq([])
    end

    it "counts all provider dois" do
      Doi.import
      sleep 2

      response = subject.stats_query(provider_id: "datacite")
      expect(response.results.total).to eq(3)
      expect(response.aggregations.created.buckets).to eq([{ "doc_count" => 3, "key" => 1420070400000, "key_as_string" => "2015" }])
    end

    it "counts all provider dois no dois" do
      Doi.import
      sleep 2

      response = subject.stats_query(provider_id: "abc")
      expect(response.results.total).to eq(0)
      expect(response.aggregations.created.buckets).to eq([])
    end

    it "counts all client dois" do
      Doi.import
      sleep 2

      response = subject.stats_query(client_id: "datacite.test")
      expect(response.results.total).to eq(3)
      expect(response.aggregations.created.buckets).to eq([{ "doc_count" => 3, "key" => 1420070400000, "key_as_string" => "2015" }])
    end

    it "counts all client dois no dois" do
      Doi.import
      sleep 2

      response = subject.stats_query(client_id: "datacite.abc")
      expect(response.results.total).to eq(0)
      expect(response.aggregations.created.buckets).to eq([])
    end
  end

  describe "query_aggregations" do
    default_aggregations = Doi.default_doi_query_facets

    it "returns default aggregations when disable_facets and facets are not set" do
      aggregations = Doi.query_aggregations

      expect(aggregations.keys).to match_array(default_aggregations)
    end

    it "returns default aggregations when disable_facets is set to false" do
      aggregations = Doi.query_aggregations(disable_facets: false)

      expect(aggregations.keys).to match_array(default_aggregations)
    end

    it "returns blank aggregations when disable_facets is true" do
      aggregations = Doi.query_aggregations(disable_facets: true)

      expect(aggregations).to eq({})
    end

    it "returns blank aggregations when disable_facets is true string" do
      aggregations = Doi.query_aggregations(disable_facets: "true")

      expect(aggregations).to eq({})
    end

    it "returns default aggregations when disable_facets is false" do
      aggregations = Doi.query_aggregations(disable_facets: false)

      expect(aggregations.keys).to match_array(default_aggregations)
    end

    it "returns default aggregations when disable_facets is false string" do
      aggregations = Doi.query_aggregations(disable_facets: "false")

      expect(aggregations.keys).to match_array(default_aggregations)
    end

    it "returns selected aggregations when facets is a string" do
      facets_string = "creators_and_contributors, registrationAgencies,made_up_facet,states,registration_agencies"
      aggregations = Doi.query_aggregations(facets: facets_string)
      expected_aggregations = [:creators_and_contributors, :registration_agencies, :states]

      expect(aggregations.keys).to match_array(expected_aggregations)
    end

    it "returns blank aggregations when facets is a blank string" do
      facets_string = ""
      aggregations = Doi.query_aggregations(facets: facets_string)

      expect(aggregations).to eq({})
    end

    it "returns selected aggregations when facets is an array of symbols" do
      facets_array = [:creators_and_contributors, :registration_agencies, :states, :made_up_facet, :registration_agencies]
      aggregations = Doi.query_aggregations(facets: facets_array)
      expected_aggregations = [:creators_and_contributors, :registration_agencies, :states]

      expect(aggregations.keys).to match_array(expected_aggregations)
    end

    it "returns blank aggregations when facets is a blank array" do
      facets_array = []
      aggregations = Doi.query_aggregations(facets: facets_array)

      expect(aggregations).to eq({})
    end

    it "returns selected aggregations when facets are an array of symbols and disable_facets is false" do
      facets_array = [:creators_and_contributors, :registration_agencies, :states, :made_up_facet, :registration_agencies]
      aggregations = Doi.query_aggregations(facets: facets_array, disable_facets: false)
      expected_aggregations = [:creators_and_contributors, :registration_agencies, :states]

      expect(aggregations.keys).to match_array(expected_aggregations)
    end

    it "returns blank aggregations when facets are an array of symbols and disable_facets is true" do
      facets_array = [:creators_and_contributors, :registration_agencies, :states, :made_up_facet, :registration_agencies]
      aggregations = Doi.query_aggregations(facets: facets_array, disable_facets: true)

      expect(aggregations).to eq({})
    end
  end

  describe "formats" do
    content_url = [
      "https://redivis.com/datasets/rt7m-4ndqm48zf/tables/1dgp-0rkbx6ahe?v=1.2",
      "https://redivis.com/datasets/rt7m-4ndqm48zf/tables/7a4a-2zxc46nwb?v=1.2",
      "https://redivis.com/datasets/rt7m-4ndqm48zf/tables/jjaq-bj4qtkmhj?v=1.2",
      "https://redivis.com/datasets/rt7m-4ndqm48zf/tables/xgx0-b76w60psz?v=1.2",
      "https://redivis.com/datasets/rt7m-4ndqm48zf/tables/9sje-1mp1m3yzp?v=1.2",
      "https://redivis.com/datasets/rt7m-4ndqm48zf/tables/mz8t-6z7c5r3cd?v=1.2",
      "https://redivis.com/datasets/q6wy-ap6qgbpq2/tables/hj03-9cga8qjzc?v=1.0",
      "https://redivis.com/datasets/q6wy-ap6qgbpq2/tables/94zc-f6chvvj42?v=1.0",
      "https://redivis.com/datasets/q6wy-ap6qgbpq2/tables/9m71-5fagnse7v?v=1.0",
      "https://redivis.com/datasets/q6wy-ap6qgbpq2/tables/vw9p-a214kdxja?v=1.0",
      "https://redivis.com/datasets/q6wy-ap6qgbpq2/tables/n4bw-8ska90rm7?v=1.0",
      "https://redivis.com/datasets/q6wy-ap6qgbpq2/tables/rn5n-abygq4jsj?v=1.0",
    ]

    formats = [
      "text/csv",
      "ndjson",
      "avro",
      "parquet",
      "sas7bdat",
      "dat",
      "sav"
    ]

    let(:doi) { create(:doi,
      formats: formats
      ) }

    it "add content_url and update media" do
      doi.content_url = content_url

      doi.update_media

      expect(doi.media.count).to eq(12)
      expect(doi.media[-1].url).to eq(content_url[-1])
      expect(doi.media[-1].uid).to be_truthy
      expect(doi.media[5].media_type).to eq(formats[5])
      expect(doi.media[-1].media_type).to eq("text/plain")
      expect(doi.media_ids.count).to eq(12)
      expect(doi.media_ids[-1]).to be_truthy
      expect(doi.as_indexed_json["media_ids"].count).to eq(12)
    end
  end

  describe "primary_title" do
    let(:doi) { create(:doi) }
    titles = [{ "title" => "New title", "titleType" => "AlternativeTitle" }, { "title" => "Second title" }]

    it "is first title" do
      expect(doi.primary_title).to eq(Array.wrap(doi.titles.first))
      expect(doi.as_indexed_json.dig("primary_title")).to eq(Array.wrap(doi.titles.first))
    end

    it "is first title after update" do
      doi.titles = titles

      expect(doi.primary_title).to eq(Array.wrap(titles.first))
      expect(doi.as_indexed_json.dig("primary_title")).to eq(Array.wrap(titles.first))
    end

    it "is empty array if titles is nil" do
      doi.titles = nil

      expect(doi.primary_title).to eq([])
      expect(doi.as_indexed_json.dig("primary_title")).to eq([])
    end
  end

  describe "update publisher" do
    let(:doi) { create(:doi) }

    it "with string key hash updates publisher" do
      doi.update(publisher: { "name" => "Plazi.org taxonomic treatments database" })
      expect(doi.publisher).to eq(
        { "name" => "Plazi.org taxonomic treatments database" }
      )
    end

    it "with symbol key hash updates publisher" do
      doi.update(publisher: { name: "Plazi.org taxonomic treatments database" })
      expect(doi.publisher).to eq(
        { "name" => "Plazi.org taxonomic treatments database" }
      )
    end
  end

  describe "check schema 4.6 changes" do
    let(:doi) { FactoryBot.create(:doi,
      types: {
        "resourceTypeGeneral": "Award",
        "resourceType": "Grant"
      },
      creators: [{
        "nameType": "Personal",
        "name": "Doe, John",
        "givenName": "John",
        "familyName": "Doe",
        "contributorType": "Translator"
      }],
      related_identifiers: [
        {
          "relatedIdentifier": "RRID:SCR_123456",
          "relatedIdentifierType": "RRID",
          "relationType": "HasTranslation"
        }
      ],
      dates: [
        { "date": "2011-10-23", "dateType": "Issued" },
        { "date": "2020-03-15", "dateType": "Coverage" }
      ]
    )}

    it "saves and returns new resourceTypeGeneral values" do
      expect(doi.types["resourceTypeGeneral"]).to eq("Award")
      expect(doi.types["resourceType"]).to eq("Grant")
    end

    it "saves and returns new contributorType value" do
      expect(doi.creators.first["contributorType"]).to eq("Translator")
    end

    it "saves and returns new relatedIdentifierType value" do
      expect(doi.related_identifiers.first["relatedIdentifierType"]).to eq("RRID")
    end

    it "saves and returns new relationType value" do
      expect(doi.related_identifiers.first["relationType"]).to eq("HasTranslation")
    end

    it "saves and returns new dateType value" do
      coverage_date = doi.dates.find { |d| d["dateType"] == "Coverage" }
      expect(coverage_date["date"]).to eq("2020-03-15")
    end
  end

  describe "Importing XML metadata" do
    let(:schema_3_xml) { file_fixture("datacite_schema_3.xml").read }
    let(:client) { create(:client) }
    let(:doi) { create(:doi, aasm_state: "findable", client: client) }

    it "updates values when DOI url is invalid against client domains settings" do
      correct_types = doi.types
      incorrect_types = {
        "resourceTypeGeneral": "Project",
        "resourceType": "New Project",
        "schemaOrg": "Dataset",
        "citeproc": "dataset",
        "bibtex": "misc",
        "ris": "DATA",
      }
      # Update DOI types column to contain metadata mismatched with XML
      doi.update_column(:types, incorrect_types)
      expect(doi.types.symbolize_keys).to eq(incorrect_types.symbolize_keys)

      # Invalidate the URL against client domains setting
      client.domains = "datacite.org"
      client.save!

      # Re-import XML to assign correct types metadata values
      Doi.import_one(doi_id: doi.doi)
      doi.reload
      expect(doi.types.symbolize_keys).to eq(correct_types.symbolize_keys)
    end

    it "updates values when DOI is using an invalid Schema version" do
      correct_types = doi.types
      incorrect_types = {
        "resourceTypeGeneral": "Project",
        "resourceType": "New Project",
        "schemaOrg": "Dataset",
        "citeproc": "dataset",
        "bibtex": "misc",
        "ris": "DATA",
      }
      # Update DOI types column to contain metadata mismatched with XML
      doi.update_column(:types, incorrect_types)
      expect(doi.types.symbolize_keys).to eq(incorrect_types.symbolize_keys)

      # Invalidate the Schema version
      doi.xml = schema_3_xml
      doi.save!(validate: false)

      # Re-import XML to assign correct types metadata values
      Doi.import_one(doi_id: doi.doi)
      doi.reload
      expect(doi.types.symbolize_keys).to eq(correct_types.symbolize_keys)
    end
  end

  describe "container" do
    let(:doi) { create(:doi, types: { resourceTypeGeneral: "JournalArticle" }, related_items: nil, descriptions: nil) }

    it "when no container information is available" do
      expect(doi.container).to eq({})
    end

    it "when container is set" do
      doi.container = {
        "type": "Series",
        "identifier": "10.17605/OSF.IO/CEA94",
        "identifierType": "DOI"
      }
      expect(doi.container).to eq({
        "type" => "Series",
        "identifier" => "10.17605/OSF.IO/CEA94",
        "identifierType" => "DOI"
      })
    end

    it "when SeriesInformation description and relatedIdentifier IsPartOf is available" do
      doi.descriptions = [
        { "descriptionType" => "SeriesInformation",
          "description" => "series title, volume(issue), firstpage-lastpage", },
      ]
      doi.related_identifiers = [
        { "relatedIdentifier": "10.5438/0000-00ss",
          "relatedIdentifierType": "DOI",
          "relationType": "IsPartOf" }
      ]
      expect(doi.container).to eq({
        "firstPage" => "firstpage",
        "identifier" => "10.5438/0000-00ss",
        "identifierType" => "DOI",
        "issue" => "issue",
        "lastPage" => "lastpage",
        "title" => "series title",
        "type" => "Series",
        "volume" => "volume"
      })
    end

    it "when relatedItem IsPublishedIn is available" do
      doi.descriptions = [
        { "descriptionType" => "SeriesInformation",
          "description" => "series title, volume(issue), firstpage-lastpage", },
      ]
      doi.related_items = [
        {
          "relatedItemType": "Journal",
          "relationType": "IsPublishedIn",
          "relatedItemIdentifier": {
            "relatedItemIdentifier": "3034-834X",
            "relatedItemIdentifierType": "ISSN"
          },
          "creators": [
            {
              "nameType": "Personal",
              "name": "Smith, John",
              "givenName": "John",
              "familyName": "Smith"
            }
          ],
          "titles": [
            {
              "title": "Understanding the fictional John Smith"
            },
            {
              "title": "A detailed look",
              "titleType": "Subtitle"
            }
          ],
          "volume": "776",
          "issue": "1",
          "number": "1",
          "numberType": "Chapter",
          "firstPage": "50",
          "lastPage": "60",
          "publisher": "Example Inc",
          "publicationYear": "1776",
          "edition": "1",
          "contributors": [
            {
              "name": "Hallett, Richard",
              "givenName": "Richard",
              "familyName": "Hallett",
              "contributorType": "ProjectLeader"
            },
            {
              "name": "Ross, Cody",
              "givenName": "Cody",
              "familyName": "Ross",
              "contributorType": "Editor"
            },
            {
              "name": "Stathis, Kelly",
              "givenName": "Kelly",
              "familyName": "Stathis",
              "contributorType": "Editor"
            },
            {
              "name": "Doe, Jane",
              "givenName": "Jane",
              "familyName": "Doe",
              "contributorType": "Translator"
            }
          ]
        }
      ]
      expect(doi.container).to eq({
        "firstPage" => "50",
        "identifier" => "3034-834X",
        "identifierType" => "ISSN",
        "issue" => "1",
        "lastPage" => "60",
        "title" => "Understanding the fictional John Smith",
        "type" => "Series",
        "volume" => "776",
        "edition" => "1",
        "number" => "1",
        "chapterNumber" => "1"
      })
    end
  end

  describe "with funding references" do
    let(:doi) { create(:doi,
      funding_references:
        [
            {
              "awardUri": "info:eu-repo/grantAgreement/EC/FP7/282625/",
              "awardTitle": "MOTivational strength of ecosystem services and alternative ways to express the value of BIOdiversity",
              "funderName": "European Commission",
              "awardNumber": "282625",
              "funderIdentifier": "https://doi.org/10.13039/501100000780",
              "funderIdentifierType": "Crossref Funder ID"
            },
            {
              "awardUri": "info:eu-repo/grantAgreement/EC/FP7/284382/",
              "awardTitle": "Institutionalizing global genetic-resource commons. Global Strategies for accessing and using essential public knowledge assets in the life sciences.",
              "funderName": "European Commission",
              "awardNumber": "284382",
              "funderIdentifier": "https://ror.org/00a0jsq62",
              "funderIdentifierType": "ROR"
            }
        ]
      ) }

    it "has normalized funding references in funder_rors" do
      expect(doi.funder_rors).to eq(["https://ror.org/00k4n6c32", "https://ror.org/00a0jsq62"])
      expect(doi.as_indexed_json["funder_rors"]).to eq(["https://ror.org/00k4n6c32", "https://ror.org/00a0jsq62"])
    end

    it "has funder ancestor ROR in funder_parent_rors" do
      expect(doi.funder_parent_rors).to eq(["https://ror.org/019w4f821", "https://ror.org/04cw6st05"])
      expect(doi.as_indexed_json["funder_parent_rors"]).to eq(["https://ror.org/019w4f821", "https://ror.org/04cw6st05"])
    end
  end

  describe "enrichable" do
    describe "#enrichment_field" do
      let(:doi) { create(:doi, aasm_state: "findable", agency: "datacite") }

      it "maps alternatveIdentifiers to alternate_identifiers" do
        expect(doi.enrichment_field("alternateIdentifiers")).to(eq("alternate_identifiers"))
      end

      it "maps creators to creators" do
        expect(doi.enrichment_field("creators")).to(eq("creators"))
      end

      it "maps titles to titles" do
        expect(doi.enrichment_field("titles")).to(eq("titles"))
      end

      it "maps publisher to publisher" do
        expect(doi.enrichment_field("publisher")).to(eq("publisher"))
      end

      it "maps publicationYear to publication_year" do
        expect(doi.enrichment_field("publicationYear")).to(eq("publication_year"))
      end

      it "maps subjects to subjects" do
        expect(doi.enrichment_field("subjects")).to(eq("subjects"))
      end

      it "maps contributors to contributors" do
        expect(doi.enrichment_field("contributors")).to(eq("contributors"))
      end

      it "maps dates to dates" do
        expect(doi.enrichment_field("dates")).to(eq("dates"))
      end

      it "maps language to language" do
        expect(doi.enrichment_field("language")).to(eq("language"))
      end

      it "maps types to types" do
        expect(doi.enrichment_field("types")).to(eq("types"))
      end

      it "maps relatedIdentifiers to related_identifiers" do
        expect(doi.enrichment_field("relatedIdentifiers")).to(eq("related_identifiers"))
      end

      it "maps relatedItems to related_items" do
        expect(doi.enrichment_field("relatedItems")).to(eq("related_items"))
      end

      it "maps sizes to sizes" do
        expect(doi.enrichment_field("sizes")).to(eq("sizes"))
      end

      it "maps formats to formats" do
        expect(doi.enrichment_field("formats")).to(eq("formats"))
      end

      it "maps version to version" do
        expect(doi.enrichment_field("version")).to(eq("version"))
      end

      it "maps rightsList to rights_list" do
        expect(doi.enrichment_field("rightsList")).to(eq("rights_list"))
      end

      it "maps descriptions to descriptions" do
        expect(doi.enrichment_field("descriptions")).to(eq("descriptions"))
      end

      it "maps geoLocations to geo_locations" do
        expect(doi.enrichment_field("geoLocations")).to(eq("geo_locations"))
      end

      it "maps fundingReferences to funding_references" do
        expect(doi.enrichment_field("fundingReferences")).to(eq("funding_references"))
      end
    end
  end
end
