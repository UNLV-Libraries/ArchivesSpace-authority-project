<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:ead="urn:isbn:1-931666-22-9" exclude-result-prefixes="xs xd" version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jul 21, 2017</xd:p>
            <xd:p><xd:b>Author:</xd:b> Seth Shaw</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:output method="text" omit-xml-declaration="yes" encoding="utf-8"/>

    <!-- Tab variable for creating TSV file -->
    <xsl:variable name="tab">
        <xsl:text>&#x09;</xsl:text>
    </xsl:variable>

    <!-- New Line variable for creating new rows in TSV file -->
    <xsl:variable name="newline">
        <xsl:text>&#xa;</xsl:text>
    </xsl:variable>

    <xsl:template match="/">

        <!-- header fields -->
        <xsl:text>ref_id</xsl:text>
        <xsl:value-of select="$tab"/>
        <xsl:text>unitid</xsl:text>
        <xsl:value-of select="$tab"/>
        <xsl:text>c01</xsl:text>
        <xsl:value-of select="$tab"/>
        <xsl:text>c02</xsl:text>
        <xsl:value-of select="$tab"/>
        <xsl:text>c03</xsl:text>
        <xsl:value-of select="$tab"/>
        <xsl:text>c04</xsl:text>
        <xsl:value-of select="$tab"/>
        <xsl:text>c05</xsl:text>
        <xsl:value-of select="$tab"/>
        <xsl:text>type</xsl:text>
        <xsl:value-of select="$tab"/>
        <xsl:text>date</xsl:text>
        <xsl:value-of select="$tab"/>
        <xsl:text>extent</xsl:text>
        <xsl:value-of select="$tab"/>
        <xsl:text>odd</xsl:text>
        <xsl:value-of select="$tab"/>
        <xsl:text>container 1 type</xsl:text>
        <xsl:value-of select="$tab"/>
        <xsl:text>container 1 value</xsl:text>
        <xsl:value-of select="$tab"/>
        <xsl:text>container 2 type</xsl:text>
        <xsl:value-of select="$tab"/>
        <xsl:text>container 2 value</xsl:text>
        <!-- <xsl:value-of select="$tab"/>
        <xsl:text>scopecontent</xsl:text>
         -->
        <xsl:value-of select="$newline"/>

        <xsl:apply-templates select="//ead:c01"/>

    </xsl:template>

    <xsl:template match="ead:c01 | ead:c02 | ead:c03 | ead:c04 | ead:c05">

        <xsl:value-of select="normalize-space(@id)"/>
        <xsl:value-of select="$tab"/>

        <xsl:value-of select="normalize-space(ead:did/ead:unitid)"/>
        <xsl:value-of select="$tab"/>

        <!-- I would rather this be recursive, but it works. -->
        <xsl:choose>
            <xsl:when test="name() = 'c05'">
                <xsl:value-of select="normalize-space(../../../../ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="normalize-space(../../../ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="normalize-space(../../ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="normalize-space(../ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="normalize-space(ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
            </xsl:when>
            <xsl:when test="name() = 'c04'">
                <xsl:value-of select="normalize-space(../../../ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="normalize-space(../../ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="normalize-space(../ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="normalize-space(ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="$tab"/>
            </xsl:when>
            <xsl:when test="name() = 'c03'">
                <xsl:value-of select="normalize-space(../../ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="normalize-space(../ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="normalize-space(ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="$tab"/>
            </xsl:when>
            <xsl:when test="name() = 'c02'">
                <xsl:value-of select="normalize-space(../ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="normalize-space(ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="$tab"/>
            </xsl:when>
            <xsl:when test="name() = 'c01'">
                <xsl:value-of select="normalize-space(ead:did/ead:unittitle)"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="$tab"/>
                <xsl:value-of select="$tab"/>
            </xsl:when>
        </xsl:choose>

        <!-- level -->
        <xsl:value-of select="@level"/>
        <xsl:value-of select="$tab"/>

        <!-- date -->
        <xsl:for-each select="ead:did/ead:unitdate">
            <xsl:if test="position() > 1">
                <xsl:text>, </xsl:text>
            </xsl:if>
            <xsl:value-of select="normalize-space(.)"/>
        </xsl:for-each>
        <xsl:value-of select="$tab"/>

        <!-- physdesc extent -->
        <xsl:choose>
            <xsl:when
                test="count(ead:did/ead:physdesc/ead:extent[@altrender = 'materialtype spaceoccupied']) > 1">
                <xsl:for-each
                    select="ead:did/ead:physdesc/ead:extent[@altrender = 'materialtype spaceoccupied']">
                    <xsl:value-of select="normalize-space(.)"/>
                    <xsl:text>;</xsl:text>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of
                    select="normalize-space(ead:did/ead:physdesc/ead:extent[@altrender = 'materialtype spaceoccupied'])"
                />
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>
        <xsl:value-of
            select="normalize-space(ead:did/ead:physdesc/ead:extent[@altrender = 'carrier'])"/>
        <xsl:value-of select="$tab"/>

        <!-- odd -->
        <xsl:for-each select="ead:odd/ead:p">
            <xsl:if test="position() > 1">
                <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:value-of select="normalize-space(.)"/>
        </xsl:for-each>
        <xsl:value-of select="$tab"/>

        <!-- Top-level container ( box of flat files ) -->
        <xsl:value-of select="normalize-space(ead:did/ead:container[1]/@type)"/>
        <xsl:value-of select="$tab"/>
        <xsl:value-of select="normalize-space(ead:did/ead:container[1])"/>
        <xsl:value-of select="$tab"/>

        <!-- Second container (folder) -->
        <xsl:value-of select="normalize-space(ead:did/ead:container[2]/@type)"/>
        <xsl:value-of select="$tab"/>
        <xsl:value-of select="normalize-space(ead:did/ead:container[2])"/>

        <!--
        <xsl:value-of select="$tab"/>
        <xsl:apply-templates select="ead:scopecontent"/>
         -->

        <xsl:value-of select="$newline"/>

        <!-- If a level contains that next level, it will process it. Otherwise it will do nothing. -->
        <xsl:apply-templates select="ead:c02"/>
        <xsl:apply-templates select="ead:c03"/>
        <xsl:apply-templates select="ead:c04"/>
        <xsl:apply-templates select="ead:c05"/>

    </xsl:template>

    <xsl:template match="ead:scopecontent">
        <!-- Keep the p tags but ditch tabs and line endings. Collateral loss of emph tags. -->
        <xsl:for-each select="ead:p">
            <xsl:text>&lt;p&gt;</xsl:text>
            <xsl:value-of select="normalize-space(.)"/>
            <xsl:text>&lt;/p&gt;</xsl:text>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
