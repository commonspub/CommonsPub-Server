import * as React from 'react';
import { compose } from 'recompose';
import { graphql, GraphqlQueryControls, OperationOption } from 'react-apollo';
import styled from '../../themes/styled';

import { Trans } from '@lingui/macro';

import H4 from '../../components/typography/H4/H4';
import Main from '../../components/chrome/Main/Main';
import Community from '../../types/Community';
import Loader from '../../components/elements/Loader/Loader';
import CommunityCard from '../../components/elements/Community/Community';
import media from 'styled-media-query';
import CommunitiesLoadMore from '../../components/elements/Loadmore/community';

const { getCommunitiesQuery } = require('../../graphql/getCommunities.graphql');

interface Data extends GraphqlQueryControls {
  communities: {
    nodes: Community[];
    pageInfo: {
      startCursor: number;
      endCursor: number;
    };
  };
}

interface Props {
  data: Data;
}

class CommunitiesYours extends React.Component<Props> {
  render() {
    return (
      <Main>
        <WrapperCont>
          <Wrapper>
            <H4>
              <Trans>All Communities</Trans>
            </H4>
            {this.props.data.error ? (
              <span>
                <Trans>Error loading communities</Trans>
              </span>
            ) : this.props.data.loading ? (
              <Loader />
            ) : (
              <>
                <List>
                  {this.props.data.communities.nodes.map((community, i) => {
                    return (
                      <CommunityCard
                        key={i}
                        summary={community.summary}
                        title={community.name}
                        icon={community.icon || ''}
                        id={community.localId}
                        followed={community.followed}
                        followersCount={community.members.totalCount}
                        collectionsCount={community.collections.totalCount}
                        externalId={community.id}
                        threadsCount={community.threads.totalCount}
                      />
                    );
                  })}
                </List>
                <CommunitiesLoadMore
                  fetchMore={this.props.data.fetchMore}
                  communities={this.props.data.communities}
                />
              </>
            )}
          </Wrapper>
        </WrapperCont>
      </Main>
    );
  }
}

const WrapperCont = styled.div`
  max-width: 1040px;
  margin: 0 auto;
  width: 100%;
  height: 100%;
`;

const Wrapper = styled.div`
  display: flex;
  flex-direction: column;
  flex: 1;
  margin-bottom: 24px;

  & h4 {
    padding-left: 8px;
    margin: 0;
    border-bottom: 1px solid #dadada;
    margin-bottom: 20px !important;
    line-height: 32px !important;
    // background-color: #151b26;
    border-bottom: 1px solid #dddfe2;
    border-radius: 2px 2px 0 0;
    font-weight: bold;
    font-size: 14px !important;
    color: #151b26;
  }
`;
const List = styled.div`
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  grid-column-gap: 16px;
  grid-row-gap: 16px;

  padding-top: 0;
  ${media.lessThan('medium')`
  grid-template-columns: 1fr;
  `};
`;

const withGetCommunities = graphql<
  {},
  {
    data: {
      communities: Community[];
    };
  }
>(getCommunitiesQuery, {
  options: (props: Props) => ({
    variables: {
      limit: 15
    }
  })
}) as OperationOption<{}, {}>;

export default compose(withGetCommunities)(CommunitiesYours);
