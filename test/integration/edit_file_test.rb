require 'test_helper'

class EditFileTest < ActionDispatch::IntegrationTest

  test "invalid json produces error" do

    visit root_path

    assert page.has_link?("Edit an existing Investments.js file")
    assert page.has_link?("Create a new Investments.js file")

    click_link "Edit an existing Investments.js file"

    assert page.has_button?("Fetch my Investments.js file")

    fill_in('investment[url]', :with => JsonServer.base+'/json/malformed')

    click_button "Fetch my Investments.js file"

    assert page.has_content?("That didn't work - either the URL was wrong or the content wasn't valid.")
    assert page.has_button?("Fetch my Investments.js file")

  end

  test "irrelevant json produces error" do

    visit load_investors_path

    fill_in('investment[url]', :with => JsonServer.base+'/json/irrelevant')

    click_button "Fetch my Investments.js file"

    assert page.has_content?("We're sorry - we couldn't retrieve any data from that file.")
    assert page.has_content?("Edit your Investments.js file")

  end

  test "correct single-entry JSON works, fills form" do

    visit load_investors_path

    fill_in('investment[url]', :with => JsonServer.base+'/json/single')

    click_button "Fetch my Investments.js file"

    assert page.has_content?("Edit your Investments.js file")
    # make sure the form fields are properly filled in
    assert page.has_xpath?("//input[@value='Warren Buffet']")
    assert page.has_xpath?("//input[@value='Dummy Corp.']")
    assert page.has_xpath?("//input[@value='http://www.dummy.com']")
    assert page.has_xpath?("//input[@value='Seed']")
    assert page.has_xpath?("//input[@value='Sale']")
    assert page.has_xpath?("(//select/option[@selected='selected'])[@value='4']")
    assert page.has_xpath?("(//select/option[@selected='selected'])[@value='10']")
    assert page.has_xpath?("(//select/option[@selected='selected'])[@value='2010']")
    assert page.has_xpath?("(//select/option[@selected='selected'])[@value='2012']")
    # sanity check
    assert !page.has_xpath?("//input[@value='IPO']")
    assert !page.has_xpath?("(//select/option[@selected='selected'])[@value='1989']")

  end

  test "load a JSON file, then delete investment / round / event and regenerate file" do

    visit load_investors_path

    fill_in('investment[url]', :with => JsonServer.base+'/json/full')

    click_button "Fetch my Investments.js file"

    assert page.has_content?("Edit your Investments.js file")

    # click on the round and event links for the new investment
    page.find(:xpath, "(//a[text()='Remove this investment'])[last()]").click
    page.find(:xpath, "(//a[text()='Remove this event'])[last()]").click
    page.find(:xpath, "(//a[text()='Remove this round'])[last()]").click

    click_button "I'm done - create my Investments.js file!"

    assert page.has_content?("Dummy Corp")
    assert page.has_no_content?("Wonder Corp")
    assert page.has_no_content?("Seed")
    assert page.has_no_content?("Sale")

    results = JSON::parse(page.find(".well").text)

    assert results
    assert_equal results["investments"].length, 1

  end

  test "load a JSON file with extra cruft in it, which should be ignored" do

    visit load_investors_path

    fill_in('investment[url]', :with => JsonServer.base+'/json/cruft')

    click_button "Fetch my Investments.js file"

    assert page.has_content?("Edit your Investments.js file")

    assert page.has_xpath?("//input[@value='Dummy Corp.']")
    assert page.has_xpath?("//input[@value='http://www.dummy.com']")
    assert page.has_xpath?("//input[@value='Seed']")
    assert page.has_xpath?("//input[@value='Sale']")

    click_button "I'm done - create my Investments.js file!"

    assert page.has_content?("Dummy Corp")
    assert page.has_no_content?("123 Test Lane")
    assert page.has_no_content?("Joe")
    assert page.has_no_content?("CEO")

    assert JSON::parse(page.find(".well").text)

  end

  test "load an old-format JSON file, add investor name, should work" do

    visit load_investors_path

    fill_in('investment[url]', :with => JsonServer.base+'/json/old')

    click_button "Fetch my Investments.js file"

    assert page.has_content?("Edit your Investments.js file")
    # make sure the form fields are properly filled in
    assert page.has_xpath?("//input[@value='Dummy Corp.']")
    assert page.has_xpath?("//input[@value='http://www.dummy.com']")
    assert page.has_xpath?("//input[@value='Seed']")
    assert page.has_xpath?("//input[@value='Sale']")

    fill_in('investor[investor]', :with => "Warren Buffet")
    fill_in('investor[url]', :with => "http://buffet.com/")

    click_button "I'm done - create my Investments.js file!"

    assert page.has_content?("Your Investments.js file is ready!")
    assert page.has_content?("Warren Buffet")
    assert page.has_content?("http://buffet.com/")
    assert page.has_content?("Dummy Corp")
    assert page.has_content?("http://www.dummy.com")
    assert page.has_content?("Seed")
    assert page.has_content?("Sale")

    assert JSON::parse(page.find(".well").text)

  end

end