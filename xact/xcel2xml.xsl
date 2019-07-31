<?xml version="1.0" encoding="UTF-8"?>
<!-- This spreadsheet has been created in order to ease the transition from spreadsheet to ead
     and into ArchivesSpace. -->
<xsl:transform xmlns="urn:isbn:1-931666-22-9" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tns="http://tnsnamespace" xmlns:saxon="http://saxon.sf.net/"
    extension-element-prefixes="saxon" version="2.0">

    <!--<saxon:import-query href="sample-functions.xql"/>-->
    <xsl:output indent="yes" method="xml"
        doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
        doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" exclude-result-prefixes="#all"
        omit-xml-declaration="yes" encoding="utf-8"/>
    <xsl:strip-space elements="*"/>

    <!-- assembly required; damage may have occurred during shipping; should just produce c elements -->
    <xsl:variable name="this-doc" select="tokenize(document-uri(.),'/')[last()]"/>

    <xsl:key name="level" match="collection_level" use="text()"/>

    <!-- ************** GLOBAL VARIABLES ************** -->

    <!-- Many variables are used to allow user customization of their own local rules -->

    <!-- Text values -->
    <xsl:variable name="eadidPrefix">US::NvLN::</xsl:variable>
    <xsl:variable name="titleproperPrefix">Guide to the </xsl:variable>
    <xsl:variable name="language">ENGLISH</xsl:variable>
    <xsl:variable name="languageCode">eng</xsl:variable>


    <xsl:variable name="counter" select="0" saxon:assignable="yes"/>
    <xsl:variable name="componentCounter" select="0" saxon:assignable="yes"/>

    <!-- Default values (if not entered in spreadsheet, values here will be the default)-->
    <xsl:variable name="dateType">inclusive</xsl:variable>
    <xsl:variable name="dateExpression">undated</xsl:variable>

    <!-- Def(default) Notes-->
    <xsl:variable name="accessrestrict_def">Collection is open for research.</xsl:variable>
    <xsl:variable name="userestrict_def">Materials in this collection may be protected by copyrights
        and other rights. See &#60;extref xlink:actuate="onRequest"
        xlink:href="http://www.library.unlv.edu/speccol/research_and_services/reproductions"
        xlink:show="new" xlink:title="Reproductions and Use"> Reproductions and Use&#60;/extref> on
        the UNLV Special Collections website for more information about reproductions and
        permissions to publish.</xsl:variable>

    <xsl:template match="/">
        <ead xmlns="urn:isbn:1-931666-22-9" xmlns:xlink="http://www.w3.org/1999/xlink"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" audience="external"
            xsi:schemaLocation="urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd">


            <xsl:apply-templates select="//row[collection_level='collection']" mode="eadheader"/>

            <xsl:apply-templates select="//row[collection_level='collection']" mode="archdesc"/>
        </ead>
    </xsl:template>

    <xsl:template match="row" mode="eadheader">
        <xsl:comment>EAD HEADER</xsl:comment>
        <!--  <xsl:variable name="currentDate" as="xs:date" select="current-date()"/> -->
        <eadheader countryencoding="iso3166-1" dateencoding="iso8601" findaidstatus="under_revision"
            langencoding="iso639-2b" repositoryencoding="iso15511">
            <eadid>
                <xsl:value-of select="$eadidPrefix"/>
                <xsl:value-of select="replace(unique_identifer,'-','')"/>
            </eadid>
            <filedesc>
                <titlestmt>
                    <titleproper>
                        <xsl:value-of select="$titleproperPrefix"/>
                        <xsl:value-of select="title"/>
                    </titleproper>
                    <titleproper type="filing">
                        <xsl:value-of select="filing_title"/>
                    </titleproper>
                </titlestmt>
            </filedesc>
        </eadheader>
    </xsl:template>


    <xsl:key name="source" match="source" use="text()"/>

    <!-- arcdesc template -->
    <xsl:template match="row" mode="archdesc">
        <archdesc level="collection">
            <did>
                <!--  <xsl:variable name="currentDate" as="xs:date" select="current-date()"/> -->
                <unitid>
                    <xsl:value-of select="unique_identifer"/>
                </unitid>
                <unittitle>
                    <xsl:value-of select="title"/>
                </unittitle>
                <langmaterial>
                    <language langcode="{$languageCode}">
                        <xsl:value-of select="$language"/>
                    </language>
                </langmaterial>
                <xsl:call-template name="extent"/>
                <xsl:call-template name="unitdate"/>
                <xsl:if test="abstract != ''">
                    <abstract>
                        <xsl:value-of select="abstract" disable-output-escaping="yes"/>
                    </abstract>
                </xsl:if>
            </did>
            <xsl:call-template name="notes">
                <xsl:with-param name="generalnote" select="generalnote"/>
                <xsl:with-param name="scopecontent" select="scopecontent"/>
                <xsl:with-param name="accessrestrict" select="accessrestrict"/>
                <xsl:with-param name="userestrict" select="userestrict"/>
                <xsl:with-param name="prefercite" select="prefercite"/>
                <xsl:with-param name="arrangement" select="arrangement"/>
                <xsl:with-param name="acqinfo" select="acqinfo"/>
                <xsl:with-param name="processinfo" select="processinfo"/>
                <xsl:with-param name="bioghist" select="bioghist"/>
                <xsl:with-param name="relatedmaterial" select="relatedmaterial"/>
                <xsl:with-param name="component_level" select="false()"/>
            </xsl:call-template>

            <dsc>
                <xsl:call-template name="description"/>
            </dsc>
        </archdesc>
    </xsl:template>
    <!-- end arcdesc template -->

    <xsl:template name="notes">
        <xsl:param name="generalnote" select="null"/>
        <xsl:param name="scopecontent" select="null"/>
        <xsl:param name="userestrict" select="null"/>
        <xsl:param name="accessrestrict" select="null"/>
        <xsl:param name="prefercite" select="null"/>
        <xsl:param name="arrangement" select="null"/>
        <xsl:param name="acqinfo" select="null"/>
        <xsl:param name="processinfo" select="null"/>
        <xsl:param name="bioghist" select="null"/>
        <xsl:param name="relatedmaterial" select="null"/>
        <xsl:param name="component_level" select="null"/>

        <xsl:if test="$generalnote != ''">
            <odd>
                <xsl:attribute name="audience">
                    <xsl:text>external</xsl:text>
                </xsl:attribute>
                <head>General</head>
                <p>
                    <xsl:value-of select="$generalnote" disable-output-escaping="yes"/>
                </p>
            </odd>
        </xsl:if>
        <xsl:if test="$scopecontent != ''">
            <scopecontent>
                <xsl:attribute name="audience">
                    <xsl:text>external</xsl:text>
                </xsl:attribute>
                <head>Scope and Contents Note</head>
                <p>
                    <xsl:value-of select="$scopecontent" disable-output-escaping="yes"/>
                </p>
            </scopecontent>
        </xsl:if>

        <xsl:choose>
            <xsl:when test="$userestrict != ''">
                <userestrict>
                    <xsl:attribute name="audience">
                        <xsl:text>external</xsl:text>
                    </xsl:attribute>
                    <head>Publication Rights</head>
                    <p>
                        <xsl:value-of select="$userestrict" disable-output-escaping="yes"/>
                    </p>
                </userestrict>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$component_level eq false()">
                    <userestrict>
                        <xsl:attribute name="audience">
                            <xsl:text>external</xsl:text>
                        </xsl:attribute>
                        <head>Publication Rights</head>
                        <p>
                            <xsl:value-of select="$userestrict_def" disable-output-escaping="yes"/>
                        </p>
                    </userestrict>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:choose>
            <xsl:when test="$accessrestrict != ''">
                <accessrestrict>
                    <xsl:attribute name="audience">
                        <xsl:text>external</xsl:text>
                    </xsl:attribute>
                    <head>Access Note</head>
                    <p>
                        <xsl:value-of select="$accessrestrict" disable-output-escaping="yes"/>
                    </p>
                </accessrestrict>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$component_level eq false()">
                    <accessrestrict>
                        <xsl:attribute name="audience">
                            <xsl:text>external</xsl:text>
                        </xsl:attribute>
                        <head>Access Note</head>
                        <p>
                            <xsl:value-of select="$accessrestrict_def" disable-output-escaping="yes"
                            />
                        </p>
                    </accessrestrict>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:if test="$prefercite != ''">
            <prefercite>
                <xsl:attribute name="audience">
                    <xsl:text>external</xsl:text>
                </xsl:attribute>
                <head>Preferred Citation</head>
                <p>
                    <xsl:value-of select="$prefercite" disable-output-escaping="yes"/>
                </p>
            </prefercite>
        </xsl:if>

        <xsl:if test="$arrangement != ''">
            <arrangement>
                <xsl:attribute name="audience">
                    <xsl:text>external</xsl:text>
                </xsl:attribute>
                <head>Arrangement Note</head>
                <p>
                    <xsl:value-of select="$arrangement" disable-output-escaping="yes"/>
                </p>
            </arrangement>
        </xsl:if>
        <xsl:if test="$acqinfo != ''">
            <acqinfo>
                <xsl:attribute name="audience">
                    <xsl:text>external</xsl:text>
                </xsl:attribute>
                <head>Acquisition Note</head>
                <p>
                    <xsl:value-of select="$acqinfo" disable-output-escaping="yes"/>
                </p>
            </acqinfo>
        </xsl:if>

        <xsl:if test="$processinfo != ''">
            <processinfo>
                <xsl:attribute name="audience">
                    <xsl:text>external</xsl:text>
                </xsl:attribute>
                <head>Processing Note</head>
                <p>
                    <xsl:value-of select="$processinfo" disable-output-escaping="yes"/>
                </p>
            </processinfo>
        </xsl:if>
        <xsl:if test="$bioghist != ''">
            <bioghist>
                <xsl:attribute name="audience">
                    <xsl:text>external</xsl:text>
                </xsl:attribute>
                <head>Biographical Note</head>
                <p>
                    <xsl:value-of select="$bioghist" disable-output-escaping="yes"/>
                </p>
            </bioghist>
        </xsl:if>
        <xsl:if test="$relatedmaterial != ''">
            <relatedmaterial>
                <xsl:attribute name="audience">
                    <xsl:text>external</xsl:text>
                </xsl:attribute>
                <head>Related Materials</head>
                <p>
                    <xsl:value-of select="$relatedmaterial" disable-output-escaping="yes"/>
                </p>
            </relatedmaterial>
        </xsl:if>
    </xsl:template>

    <xsl:template name="description">
        <xsl:param name="series" select="//row[collection_level = 'series']"/>
        <xsl:param name="files" select="//row[collection_level = 'file']"/>
        <xsl:param name="rows"
            select="//row[collection_level != 'collection' and collection_level != 'series']"/>

        <xsl:for-each select="$series">
            <c01>
                <xsl:attribute name="level">
                    <xsl:value-of select="collection_level"/>
                </xsl:attribute>
                <xsl:call-template name="component"> </xsl:call-template>

                <xsl:for-each select="tokenize(subseries_reference, ',')">
                    <xsl:variable name="subseries_reference" select="."/>
                    <xsl:apply-templates
                        select="$rows[association_id = normalize-space($subseries_reference) and collection_level = 'subseries']"
                        mode="subseries"> </xsl:apply-templates>
                </xsl:for-each>
                <xsl:for-each select="tokenize(files_reference, ',')">
                    <xsl:variable name="files_reference" select="."/>
                    <xsl:apply-templates
                        select="$rows[association_id = normalize-space($files_reference) and collection_level = 'file']"
                        mode="files"> </xsl:apply-templates>
                </xsl:for-each>
            </c01>
        </xsl:for-each>
        <xsl:for-each select="$files">
            <xsl:if test="not(association_id) or association_id = ''">
                <c01>
                    <xsl:attribute name="level">
                        <xsl:value-of select="collection_level"/>
                    </xsl:attribute>
                    <xsl:call-template name="component"> </xsl:call-template>
                    <xsl:for-each select="tokenize(files_reference, ',')">
                        <xsl:variable name="files_reference" select="."/>
                        <xsl:apply-templates
                            select="$rows[association_id = normalize-space($files_reference) and collection_level = 'file']"
                            mode="files"> </xsl:apply-templates>
                    </xsl:for-each>
                </c01>
            </xsl:if>
        </xsl:for-each>

    </xsl:template>

    <xsl:template match="row" mode="subseries">
        <xsl:param name="rows"
            select="//row[collection_level != 'collection' and collection_level != 'series']"/>
        <c>
            <xsl:attribute name="level">
                <xsl:value-of select="collection_level"/>
            </xsl:attribute>
            <xsl:call-template name="component"> </xsl:call-template>
            <xsl:for-each select="tokenize(subseries_reference, ',')">
                <xsl:variable name="subseries_reference" select="."/>
                <xsl:apply-templates
                    select="$rows[association_id = normalize-space($subseries_reference) and collection_level = 'subseries']"
                    mode="subseries"> </xsl:apply-templates>
            </xsl:for-each>
            <xsl:for-each select="tokenize(files_reference, ',')">
                <xsl:variable name="files_reference" select="."/>
                <xsl:apply-templates
                    select="$rows[association_id = normalize-space($files_reference) and collection_level = 'file']"
                    mode="files"> </xsl:apply-templates>
            </xsl:for-each>
        </c>
    </xsl:template>

    <xsl:template match="row" mode="files">
        <xsl:param name="rows" select="//row[collection_level = 'file']"/>
        <xsl:param name="component_level"/>
        <xsl:element name="c">
            <xsl:attribute name="level">
                <xsl:value-of select="collection_level"/>
            </xsl:attribute>
            <xsl:call-template name="component"> </xsl:call-template>
            <xsl:for-each select="tokenize(files_reference, ',')">
                <xsl:variable name="files_reference" select="."/>
                <xsl:apply-templates
                    select="$rows[association_id = normalize-space($files_reference) and collection_level = 'file']"
                    mode="files"> </xsl:apply-templates>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>

    <xsl:template name="component">
        <did>
            <xsl:if test="title ne ''">
                <unittitle>
                    <xsl:value-of select="title"/>
                </unittitle>
            </xsl:if>
            <xsl:if test="unique_identifer ne ''">
                <unitid>
                    <xsl:value-of select="unique_identifer"/>
                </unitid>
            </xsl:if>
            <xsl:if test="date_expression ne '' or date_begin ne ''or date_end ne ''">
                <xsl:call-template name="unitdate"/>
            </xsl:if>

            <xsl:if test="extent_number ne ''">
                <xsl:call-template name="extent"/>
            </xsl:if>

            <xsl:if test="instance_type ne ''">
                <xsl:call-template name="container"/>
            </xsl:if>

        </did>
        <xsl:call-template name="notes">
            <xsl:with-param name="generalnote" select="generalnote"/>
            <xsl:with-param name="scopecontent" select="scopecontent"/>
            <xsl:with-param name="accessrestrict" select="accessrestrict"/>
            <xsl:with-param name="userestrict" select="userestrict"/>
            <xsl:with-param name="prefercite" select="prefercite"/>
            <xsl:with-param name="arrangement" select="arrangement"/>
            <xsl:with-param name="processinfo" select="processinfo"/>
            <xsl:with-param name="bioghist" select="bioghist"/>
            <xsl:with-param name="relatedmaterial" select="relatedmaterial"/>
            <xsl:with-param name="acqinfo" select="acqinfo"/>
            <xsl:with-param name="component_level" select="true()"/>
        </xsl:call-template>
    </xsl:template>

    <!-- unitdate template -->
    <xsl:template name="unitdate">
        <unitdate>
            <!-- Date type -->
            <xsl:choose>
                <xsl:when test="date_type/text()">
                    <xsl:attribute name="type">
                        <xsl:value-of select="date_type/text()"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="type">
                        <xsl:value-of select="$dateType"/>
                    </xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <!-- Normal form -->
            <xsl:choose>
                <xsl:when test="date_begin/text() != '' and date_end/text() != ''">
                    <xsl:attribute name="normal">
                        <xsl:value-of select="normalize-space(date_begin)"/>
                        <xsl:text>/</xsl:text>
                        <xsl:value-of select="normalize-space(date_end)"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="date_begin/text() != ''">
                    <xsl:attribute name="normal">
                        <xsl:value-of select="normalize-space(date_begin)"/>
                        <xsl:text>/</xsl:text>
                        <xsl:value-of select="normalize-space(date_begin)"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="date_end/text() != ''">
                    <xsl:attribute name="normal">
                        <xsl:value-of select="normalize-space(date_end)"/>
                        <xsl:text>/</xsl:text>
                        <xsl:value-of select="normalize-space(date_end)"/>
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
            <!-- Certainty attribute -->
            <xsl:choose>
                <xsl:when test="date_certainty/text() != ''">
                    <xsl:attribute name="certainty">
                        <xsl:value-of select="normalize-space(date_certainty)"/>
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
            <!-- Date expression -->
            <xsl:choose>
                <xsl:when test="date_expression/text()">
                    <xsl:value-of select="date_expression"/>
                </xsl:when>
                <!-- ArchivesSpace doesn't include certainty as part of dates in component titles, so we add a date expression that does. -->
                <xsl:when test="date_certainty/text() != ''">
                    <xsl:choose>
                        <xsl:when test="date_certainty = 'approximate'">
                            <xsl:text>approximately </xsl:text>
                        </xsl:when>
                        <xsl:when test="date_certainty = 'questionable'">
                            <xsl:text>possibly </xsl:text>
                        </xsl:when>
                        <xsl:when test="date_certainty = 'inferred'">
                            <xsl:text>probably </xsl:text>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="date_begin/text() != '' and date_end/text() != ''">
                            <xsl:value-of select="normalize-space(date_begin)"/>
                            <xsl:text>-</xsl:text>
                            <xsl:value-of select="normalize-space(date_end)"/>
                        </xsl:when>
                        <xsl:when test="date_begin/text() != ''">
                            <xsl:value-of select="normalize-space(date_begin)"/>
                        </xsl:when>
                        <xsl:when test="date_end/text() != ''">
                            <xsl:value-of select="normalize-space(date_end)"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="date_begin/text() != '' or date_end/text() != ''">
                    <!-- Leave empty. ArchivesSpace will take care of it.-->
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$dateExpression"/>
                </xsl:otherwise>
            </xsl:choose>
        </unitdate>
    </xsl:template>
    <!--end  unitdate template -->


    <!-- extent template -->
    <xsl:template name="extent">
        <xsl:if test="extent_number ne ''">
            <physdesc altrender="whole">
                <xsl:choose>
                    <xsl:when test="collection_level/text()">
                        <extent altrender="materialtype spaceoccupied">
                            <xsl:value-of select="extent_number"/>
                            <xsl:text> </xsl:text>
                            <xsl:value-of select="extent_type"/>
                        </extent>
                    </xsl:when>
                    <xsl:otherwise>
                        <extent altrender="materialtype spaceoccupied">
                            <xsl:value-of select="extent_number"/>
                            <xsl:text> </xsl:text>
                            <xsl:value-of select="extent_type"/>
                        </extent>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="extent_summary ne ''">
                    <extent altrender="carrier">
                        <xsl:value-of select="extent_summary"/>
                    </extent>
                </xsl:if>
            </physdesc>
        </xsl:if>
    </xsl:template>
    <!--end  extent template -->

    <!-- container template -->
    <xsl:template name="container">
        <xsl:if
            test="instance_type ne '' and container_type_1 ne '' and container_indicator_1 ne ''">
            <container id="parent-id{$counter}" label="{instance_type}" type="{container_type_1}">
                <xsl:value-of select="container_indicator_1"/>
            </container>
            <xsl:if test="container_type_2 ne ''">
                <container parent="parent-id{$counter}" type="{container_type_2}">
                    <xsl:value-of select="container_indicator_2"/>
                </container>
            </xsl:if>
            <xsl:if test="container_type_3 ne ''">
                <container parent="parent-id{$counter}" type="{container_type_3}">
                    <xsl:value-of select="container_indicator_3"/>
                </container>
            </xsl:if>
            <saxon:assign name="counter" select="$counter+1"/>
        </xsl:if>
    </xsl:template>
    <!--end  extent template -->


    <!-- this is to demonstrate template processing -->
    <xsl:template name="event">
        <xsl:for-each select="//Event">
            <test>
                <xsl:value-of select="concat('Event no. ',position())"/>
            </test>
        </xsl:for-each>
    </xsl:template>
</xsl:transform>
